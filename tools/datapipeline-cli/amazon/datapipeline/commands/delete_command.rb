require 'amazon/datapipeline/webservice-client'

module Amazon
  module DataPipeline

    class DeleteCommand < Command
      def initialize(name)
        super(name)
        requires_pipeline_id
      end

      def run(client, parameters)
        puts "Command: Delete #{parameters.pipeline_id}" if parameters.verbose
        client.delete_pipeline parameters.pipeline_id
        puts "Deleted pipeline '#{parameters.pipeline_id}'"
      end
    end

  end
end
