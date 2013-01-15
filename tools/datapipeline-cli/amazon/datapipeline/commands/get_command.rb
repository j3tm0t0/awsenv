require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/queries'
require 'amazon/datapipeline/validation'

module Amazon
  module DataPipeline

    class GetCommand < Command
      def initialize(name, file)
        super(name)
        @file = file
        requires_pipeline_id
      end

      def handle_subcommand(command, args)
        case command
        when '--version'
          @version = args
        else
          super
        end
      end

      def run(client, parameters)
        puts "Command: Get #{@file}" if parameters.verbose

        if @file && File.exists?(@file) && File.file?(@file)
          warn "The specified filename '#{@file}' already exists."
          exit 1
        end

        pipelineObjects = client.get_pipeline_definition parameters.pipeline_id, @version
        puts pipelineObjects.inspect if parameters.verbose

        pipeline = Pipeline.from_wire(pipelineObjects["pipelineObjects"])
        if @file
          begin
            File.open(@file, 'w') {|f| f.puts JSON.pretty_generate(pipeline) }
            puts "Pipeline definition retrieved and saved to: #{@file}"
          rescue => e
            warn "Unable to write pipeline definition to file: #{@file}"
            warn "Failed with error: #{e.message}"
            warn e.backtrace.inspect if parameters.trace
            exit 1
          end
        else
          puts JSON.pretty_generate(pipeline)
          puts "Pipeline definition retrieved."
        end
      end
    end

  end
end
