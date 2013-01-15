require 'amazon/datapipeline/webservice-client'

module Amazon
  module DataPipeline

    class CommandParameters
      attr_reader :pipeline_id, :limit, :verbose, :trace, :force

      def initialize(pipeline_id, limit=nil, verbose=nil, trace=nil, force=nil)
        @pipeline_id = pipeline_id # nil is acceptable
        @limit = limit.nil? ? 100 : limit
        @verbose = verbose.nil? ? false : verbose
        @trace = trace.nil? ? false : trace
        @force = force.nil? ? false: force
        
        @PAGENATION_MIN_LIMIT = 50
        @PAGENATION_MAX_LIMIT = 500
        if @limit < @PAGENATION_MIN_LIMIT
          puts "CommandParameters: Pagination limit must be at least #{@PAGENATION_MIN_LIMIT}."
          exit 1
        elsif @PAGENATION_MAX_LIMIT < @limit
          puts "CommandParameters: Pagination limit must not be greater than #{@PAGENATION_MAX_LIMIT}."
          exit 1
        end
      end
    end

    class Command
      attr_reader :name

      def initialize(name)
        @name = name
        @requires_pipeline_id = false
        @cannot_run_after_commands = []
      end

      def check_pipeline_id(pipeline_id)
        if pipeline_id.nil? then
          puts "Command requires a valid pipeline be specified via either --id or --create"
          exit 1
        end
      end

      def requires_pipeline_id
        @requires_pipeline_id = true
      end

      def cannot_run_after(commands)
        @cannot_run_after_commands = commands
      end

      def cannot_run_after?(command)
        @cannot_run_after_commands.include?(command.class())
      end

      def handle_subcommand(command, args)
        puts "The command '#{self.name}' does not accept the modifier '#{command}'."
        exit 1
      end

      def run_with_checks(client, parameters)
        run_with_pipeline_id_check(client, parameters)
      end

      def run_with_pipeline_id_check(client, parameters)
        check_pipeline_id parameters.pipeline_id if @requires_pipeline_id
        run(client, parameters)
      end

      def run(client, parameters)
        raise "Must override Command::run"
      end
    end

    class CommandRunner < Command
      def initialize
        @commands = []
      end

      def add(command)
        @commands.each do |c|
          if command.cannot_run_after?(c) then
            puts "Warning: Command-line argument '#{command.name}' normally does not occur after argument '#{c.name}'."
          end
        end
        @commands << command
      end

      def handle_subcommand(command, args=nil)
        if @commands.empty? then
          puts "No command specified before the sub-command '#{command}'."
          exit 1
        end

        @commands.last.handle_subcommand(command, args)
      end

      def empty?
        @commands.empty?
      end

      def run(client, parameters)
        @commands.each do |command|
          command.run_with_checks(client, parameters)
        end
      end
    end

  end
end
