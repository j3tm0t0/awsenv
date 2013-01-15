require 'optparse'
require 'ostruct'
require 'uri'
require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/credentials'

require 'amazon/datapipeline/commands/pipeline_commands'
require 'amazon/datapipeline/commands/command'
require 'amazon/datapipeline/commands/get_command'
require 'amazon/datapipeline/commands/get_objects_command'
require 'amazon/datapipeline/commands/put_command'
require 'amazon/datapipeline/commands/activate_command'
require 'amazon/datapipeline/commands/validate_command'
require 'amazon/datapipeline/commands/set_status_command'
require 'amazon/datapipeline/commands/delete_command'
require 'amazon/datapipeline/commands/list_runs_command'
require 'amazon/datapipeline/commands/list_pipelines_command'
require 'amazon/datapipeline/commands/evaluate_expression_command'

module Amazon
  module DataPipeline
    class PipelineCLI
      attr_reader :client 
      attr_reader :options

      def initialize(args)
        #
        #  Force the time zone to UTC for this process.
        #  This means that all command line dates will be interpreted
        #  as being in UTC regardless of the computers settings.
        #
        ENV['TZ'] = 'UTC'

        @arguments = args
        @options = OpenStruct.new 
        @options.verbose = false
        @options.trace = false
        @options.force = false
        
        @commands = CommandRunner.new
        @pipeline_command = PipelineIdCommandRunner.new

        parse_commands
      end

      def run
        @client = DataPipelineService.new(getConfig)

        puts "Verbose mode enabled" if @options.verbose

        #
        #  Run all queued commands in a global rescue block.
        #
        pipeline_id = @pipeline_command.getPipelineId(@client, @options.verbose)
        parameters = CommandParameters.new(pipeline_id, @options.limit,
                                           @options.verbose, @options.trace, @options.force)

        puts get_options if (@commands.empty? and @pipeline_command.pipeline_command == nil)

        begin
          @commands.run(@client, parameters)
        rescue => e
          warn "DataPipeline CLI exited abnormally with the following error:\n #{e.message}"
          warn e.backtrace if parameters.trace
          exit 1
        end

      end

      def parse_commands
        get_options.parse!(@arguments)
      end

      def get_options
        opts = OptionParser.new(:unknown_options_action => :raise)
        opts.banner = "Usage: #{opts.program_name} [options]"
        opts.separator ""
        opts.separator "Examples:"
        opts.separator "Create a new pipeline in the service:"
        opts.separator "   #{opts.program_name} --credentials my_credentials.json --create 'example' --put example.dp"
        opts.separator "Upload pipeline to the service:"
        opts.separator "   #{opts.program_name} --credentials my_credentials.json --id 'df-1234567890' --put example.dp"
        opts.separator "Download the latest version of a pipeline into a file:"
        opts.separator "   #{opts.program_name} --credentials my_credentials.json --id 'df-1234567890' --get example.dp"
        opts.separator ""

        opts.separator " "
        opts.separator "Options:"

        opts.on('--id ID', 'Use the specified pipeline id') do |id|
          @pipeline_command.add(PipelineIdCommand.new(id))
        end
        
        opts.on('--description DESCRIPTION', 'Description of the pipeline to be created. Used with --create command.') do |description|
          pipeline_command = @pipeline_command.pipeline_command
          if pipeline_command == nil || (! pipeline_command.instance_of?(PipelineNameCreateCommand)) then
            puts "Need to specify --create NAME before --description"
            exit 1
          end
          pipeline_command.description = description
        end

        opts.on_tail('-h', '--help', 'Print this help message') do
          puts opts
          exit
        end

        opts.on('--secret-key ACCESS_KEY', 'Use the specified secret key') do |key|
          @options.secret_key = key
        end

        opts.on('--access-key SECRET_KEY', 'Use the specified access key') do |key|
          @options.access_key = key
        end

        opts.on('--credentials FILE', 'Use the specified json file for credentials') do |file|
          @options.credentials = file
        end

        opts.on('--endpoint URL', 'Use the datapipeline service at the specified end point') do |url|
          @options.endpoint = url
        end

        opts.on('--region REGION', 'Use the DataPipeline service at the specified end point') do |region|
          @options.region = region
        end

        opts.on('--limit LIMIT', Integer,
                'Specify the field limit for pagination of objects') do |limit|
          @options.limit = limit
        end

        opts.on('--timeout SECONDS', Integer,
                'Specify the read timeout for the http connection') do |timeout|
          @options.timeout = timeout
        end

        opts.separator " "

        opts.on('-v', '--verbose', 'Print verbose user output') { @options.verbose = true }
        opts.on('-t', '--trace', 'Print detailed debugging output') { @options.trace = true }
        opts.on('-f', '--force', 'Submit pipeline without backfill check') { @options.force = true }
          
        opts.separator " "
        opts.separator "Pipeline commands:"

        opts.on('--create NAME', 'Create a new pipeline with the specified name') do |name|
          @pipeline_command.add(PipelineNameCreateCommand.new(name))
        end

        opts.on('--put FILE', 'Send a pipeline file to the DataPipeline service.') do |file|
          @commands.add(PutCommand.new("--put", file))
        end

        opts.on('--activate', 'Activate the specified pipeline.') do
          @commands.add(ActivateCommand.new("--activate"))
        end
        
        opts.on('--validate FILE',
                'Send pipeline file for validation only without submitting') do |file|
          @commands.add(ValidateCommand.new("--validate", file))
        end

        opts.on('--get [FILE]',
                'Get an entire pipeline and save to file. If no file is specified, write to standard out.') do |file|
          @commands.add(GetCommand.new("--get", file))
        end
        
        opts.on('--version VERSION', 'Pipeline definition version for --get command. Legal values are ACTIVE/LATEST. Defaults to LATEST.') do |version|
          @commands.handle_subcommand('--version', version)
        end
        
        opts.on('--delete', 'Delete and cancel the specified pipeline.  Once deleted, a pipeline cannot be restarted.') do
          @commands.add(DeleteCommand.new("--delete"))
        end
        
        opts.on('--list-pipelines', 'List pipelines that you can access') do
          @commands.add(ListPipelinesCommand.new("--list-pipelines"))
        end

        opts.separator " "
        opts.separator "Query running or run objects:"      

        opts.on('--list-runs', 'List runs of pipeline objects.') do
          @commands.add(ListRunsCommand.new("--list-runs"))
        end
        
        opts.on('--get-objects-by-id OBJECT_IDS', 'Get specific objects by id') do |input|
           @commands.add(GetObjectsCommand.new("--get-objects-by-id", input.split(',')))
        end
        
        opts.on('--eval EXPR', 'Evaluate EXPR in the context of OBJECT_ID') do |expr|
          @commands.add(EvaluateExpressionCommand.new("--eval", expr))
        end

        opts.on('--object-id OBJECT_ID', 'Evaluate EXPR in the context of OBJECT_ID') do |object_id|
          @commands.handle_subcommand('--object-id', object_id)
        end
        
        opts.on('--status STATES', 'Specify comma separated list of states of objects for list runs') do |states|
          @commands.handle_subcommand('--status', states)
        end
        
        opts.on('--running', 'List objects in running state') do
          @commands.handle_subcommand('--running')
        end
        
        opts.on('--failed', 'List objects in failed state') do
          @commands.handle_subcommand('--failed')
        end
        
        opts.on('--start-interval INTERVAL',
                'Specify start interval for --list-runs of the form 2011-11-29T06:07:21,2011-12-06T06:07:21') do |interval|
          @commands.handle_subcommand('--start-interval', interval)
        end
        
        opts.on('--schedule-interval INTERVAL',
                'Specify schedule interval for --list-runs of the form 2011-11-29T06:07:21,2011-12-06T06:07:21') do |interval|
          @commands.handle_subcommand('--schedule-interval', interval)
        end
        
        opts.separator " "
        opts.separator "Change status of objects:"

        opts.on('--pause OBJECT_IDS',
                'Specify comma separated pipeline object ids to pause.', 
                'This only effects Activities and DataNodes.',
                'New Instance Objects will not be created while a Pipeline Object is paused and Instance Objects',
                'that are not yet in the task queue will stop checking preconditions until resumed') do |input|
          @commands.add(PauseObjectsCommand.new(input.split(',')))
        end
        
        opts.on('--resume OBJECT_IDS', 'Specify comma separated pipeline object ids to resume') do |input|
          @commands.add(ResumeObjectsCommand.new(input.split(',')))
        end
        
        opts.on('--rerun OBJECT_IDS', 'Specify comma separated list of run object ids to rerun') do |input|
          @commands.add(RerunObjectsCommand.new(input.split(',')))
        end

        opts.on('--cancel OBJECT_IDS', 'Specify comma separated list of run object ids to cancel') do |input|
          @commands.add(CancelObjectsCommand.new(input.split(',')))
        end
        
        opts.on('--mark-finished OBJECT_IDS', 'Specify comma separated list of run object ids to mark as finished') do |input|
          @commands.add(MarkFinishedObjectsCommand.new(input.split(',')))
        end
      end 
      
      def getConfig
        file_options = Credentials.new.parse_credentials(@options.credentials)

        endpoint = @options.endpoint || file_options[:endpoint]  || "https://datapipeline.us-east-1.amazonaws.com"
        uri = URI.parse(endpoint)

        config = {
          :datapipeline_endpoint => uri.host,
          :datapipeline_port => uri.port,
          :use_ssl => (uri.scheme.downcase == "https"),
          :datapipeline_region => @options.region || file_options[:region]  || 'us-east-1',
          :verbose => @options.verbose || file_options[:enable_debugging],
          :secret_access_key => @options.secret_key || file_options[:aws_secret_key],
          :access_key_id => @options.access_key || file_options[:aws_access_key],
          :http_read_timeout => @options.timeout || file_options[:timeout] || 60.0,
          :http_wire_trace => @options.trace || file_options[:trace] || false,
          :options => @options.force || file_options[:force] || false,
        }

        error_if_nil(config[:access_key_id], "Missing access-key")
        error_if_nil(config[:secret_access_key], "Missing private-key")
        config
      end
      
      def error_if_nil(value, message)
        if value == nil then
          raise RuntimeError, message
        end
      end
    end

  end
end
