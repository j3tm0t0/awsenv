require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/queries'
require 'amazon/datapipeline/validation'

module Amazon
  module DataPipeline

    class ValidateCommand < Command
      def initialize(name, file)
        super(name)
        @file = file
        requires_pipeline_id
      end

      def run(client, parameters)
        puts "Command: Put #{@file}" if parameters.verbose

        if @file.nil? then
          warn "The command '#{self.name}' requires a filename"
          exit 1
        end

        if !File.exists? @file then
          warn "The specified filename '#{@file}' does not exist."
          exit 1
        end

        #
        #  Load pipeline from file.
        #
        begin
          pipeline = Pipeline.get_pipeline File.open(@file)
        rescue => e
          warn "Pipeline definition file '#{@file}' contains parse errors"
          warn "Error: #{e.message}"
          warn e.backtrace.inspect if parameters.trace
          exit 1
        end

        begin
          warn "\nParsed pipeline:\n#{pipeline.inspect}" if parameters.trace
          output = DataPipelineServiceUtils.smart_validate_objects(client, parameters, pipeline.to_wire)
          if output["errored"] then
            DataPipelineServiceUtils.print_validation_errors output
          else
            puts "\n Pipeline is valid"
          end
        rescue => e
          warn "Failed to validate pipeline definition: '#{@file}'"
          warn "Error: #{e.message}"
          warn e.backtrace.inspect if parameters.trace
          exit 1
        end
      end
    end

  end
end

