require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/webservice-utils'

module Amazon
  module DataPipeline

    class ActivateCommand < Command
      def initialize(name)
        super(name)
        requires_pipeline_id
      end

      def run(client, parameters)
        puts "Command: Activate" if parameters.verbose

        begin
          client.activate_pipeline parameters.pipeline_id
          puts "Pipeline activated."
        rescue => e
          warn "Failed to activate pipeline."
          warn "Error: #{e.message}"
          warn e.backtrace.inspect if parameters.trace
          exit 1
        end
      end

    end
  end
end
