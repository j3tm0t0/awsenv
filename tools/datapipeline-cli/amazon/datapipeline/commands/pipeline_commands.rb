require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/validation'
require 'uuidtools'

module Amazon
  module DataPipeline

    class PipelineIdCommand
      def initialize(pipeline_id)
        @pipeline_id = pipeline_id
      end

      def getPipelineId(client, verbose)
        puts "Using pipeline with id: #{@pipeline_id}" if verbose
        puts PipelineValidator.new(client, verbose).get_warnings(@pipeline_id)
        @pipeline_id
      end
    end

    class PipelineNameCreateCommand < PipelineIdCommand
    
      attr :description, :name
      
      def initialize(name)
        @name = name
      end

      def getPipelineId(client, verbose)
        puts "Creating pipeline with name: #{@name}" if verbose
        begin
          pipeline_id = client.create_pipeline(@name, UUIDTools::UUID.random_create, @description)
        rescue => e
          warn "Failed to create pipeline with '#{@name}'. Error: #{e.message}"
          warn e.backtrace if verbose
          exit 1
        end
        puts "Pipeline with name '#{@name}' and id '#{pipeline_id}' created."
        pipeline_id
      end
    end

    class PipelineIdCommandRunner
    
      attr :pipeline_command
      
      def initialize
        @pipeline_command = nil
      end

      def add(pipeline_command)
        if @pipeline_command then
          puts "Only one of --id or --create may be specified."
          exit 1
        end
        @pipeline_command = pipeline_command
      end

      def getPipelineId(client, verbose)
        if @pipeline_command then
          @pipeline_command.getPipelineId(client, verbose)
        else
          nil
        end
      end
    end

  end
end
