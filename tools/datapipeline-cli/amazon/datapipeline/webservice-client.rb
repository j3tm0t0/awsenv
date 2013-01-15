require 'aws/datapipeline'

module Amazon
  module DataPipeline

    class DataPipelineService
      
      RETRIABLE_EXCEPTIONS = [AWS::Core::Client::NetworkError, AWS::DataPipeline::Errors::ServerError]

      def initialize(config)
        @config = AWS.config(config)
        @client = AWS::DataPipeline.new(:config => @config).client
        @retries = 3
      end    
   
      def call_with_retry(retry_count, backoff=5, &block)
        begin
          result = block.call
        rescue *RETRIABLE_EXCEPTIONS => e
          warn e.message 
          
          if retry_count > 0 
            warn "Retrying in #{backoff} seconds..."
            sleep backoff
            result = call_with_retry(retry_count-1, backoff*2, &block)
          else
            raise e
          end
        end
        result
      end

      # List pipelines that you can access.
      # returns a hash of {name => id}
      def list_pipelines(marker)
        output = call_with_retry(@retries) {
          @client.list_pipelines(:marker => marker)
        }
        output
      end

      # Create a new data pipeline wit the given name and return the id
      def create_pipeline(name, uniqueId, description) 
        output = call_with_retry(@retries) {
          @client.create_pipeline(:name => name,
                                 :unique_id => uniqueId,
                                 :description => description)
        }
        output["pipelineId"]
      end

      # Describe objects in a pipeline
      def describe_objects(pipeline_id, object_ids, marker) 
        call_with_retry(@retries) {
          @client.describe_objects(:pipeline_id => pipeline_id,
                                  :object_ids => object_ids,
                                  :marker => marker)
        }
      end
      
      # Get pipeline definition
      def get_pipeline_definition(pipeline_id, version) 
        call_with_retry(@retries) {
          @client.get_pipeline_definition(:pipeline_id => pipeline_id, :version => version)
        }
      end

      def describe_pipelines(pipeline_ids) 
        pipeline_description_list = []
        pipeline_ids.each_slice(50) do |pipeline_ids_page|
          output = call_with_retry(@retries) {
            @client.describe_pipelines(:pipeline_ids => pipeline_ids_page)
          }
          pipeline_description_list += output["pipelineDescriptionList"]
        end

        #
        #  Flatten the object into a hash
        #
        pipeline_descriptions = []
        for pipeline_description in pipeline_description_list do
          hash = Hash.new
          hash["name"] = pipeline_description["name"]
          hash["pipelineId"] = pipeline_description["pipelineId"]
          pipeline_description[Constants::FIELD_LIST].each do |field|
            hash[field[Constants::FIELD_KEY]] = field[Constants::VALUE_STRING]
          end
          pipeline_descriptions << hash
        end
        pipeline_descriptions
      end

      def delete_pipeline(pipeline_id) 
        call_with_retry(@retries) {
          @client.delete_pipeline(:pipeline_id => pipeline_id)
        }
      end
      
      def put_pipeline_definition(pipeline_id, objects)
        output = call_with_retry(@retries) {
          @client.put_pipeline_definition(:pipeline_id => pipeline_id,
                             :pipeline_objects => objects)
          }
        output
      end
      
      def activate_pipeline(pipeline_id)
        output = call_with_retry(@retries) {
          @client.activate_pipeline(:pipeline_id => pipeline_id)
          }
        output
      end
      
      def validate_pipeline_definition(pipeline_id, objects)
        output = nil 
        objects.each_slice(1000) do |objects_page|
          output = call_with_retry(@retries) {
            @client.validate_pipeline_definition(:pipeline_id => pipeline_id,
                               :pipeline_objects => objects_page)
          }
        end
        output
      end

      def query_objects(pipeline_id, sphere, query, marker, limit) 
        call_with_retry(@retries) {
          @client.query_objects(:pipeline_id => pipeline_id,
                               :sphere => sphere,
                               :query => query,
                               :marker => marker,
                               :limit => limit)
        }
      end

      def set_status(pipeline_id, object_ids, status) 
        object_ids.each_slice(1000) do |object_ids_page|
          call_with_retry(@retries) {
            @client.set_status(:pipeline_id => pipeline_id,
                              :object_ids => object_ids_page,
                              :status => status)
          }
        end
      end

      def evaluate_expression(pipeline_id, object_id, expr)
        call_with_retry(@retries) {
          @client.evaluate_expression(
             :pipeline_id => pipeline_id, :object_id => object_id, 
             :expression => expr
          )["evaluatedExpression"]
        }
      end
    end
  end
end
