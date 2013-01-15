require 'amazon/datapipeline/webservice-client'

module Amazon
  module DataPipeline
    class DataPipelineServiceUtils

      def self.smart_put_objects (client, parameters, objects)
        warn "Pipeline objects to put:#{objects.inspect}" if parameters.trace
        output = client.put_pipeline_definition parameters.pipeline_id, objects
        output
      end
      
      def self.smart_validate_objects (client, parameters, objects)
        warn "\nPipeline objects final:\n#{objects.inspect}" if parameters.trace
        output = client.validate_pipeline_definition parameters.pipeline_id, objects
        output
      end

     
      def self.print_validation_errors(validation_output)
        if validation_output["errored"] then
          warn "Invalid pipeline definition: \n"
          warn "Pipeline Object\tError\n"
          for validationError in validation_output["validationErrors"] do
            for error in validationError["errors"] do
              warn "#{validationError["id"] }\t#{error}"
            end
          end
          exit 1
        end
      end

    end
  end
end

