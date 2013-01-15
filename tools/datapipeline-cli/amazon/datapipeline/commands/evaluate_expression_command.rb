require 'rubygems'
require 'json'
require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/webservice-utils'
require 'amazon/datapipeline/template'
require 'amazon/datapipeline/queries'

module Amazon
  module DataPipeline

    class EvaluateExpressionCommand < Command

      attr_reader :object_id, :expr

      def initialize(name, expr)
        super(name)
        @expr = expr
        requires_pipeline_id
      end

      def handle_subcommand(command, args)
        if command == '--object-id' then
          @object_id = args
        else
          super
        end
      end          

      def run(client, parameters)
        pipeline_id = parameters.pipeline_id
        if object_id == nil then
          raise "Missing required argument --object-id after --eval"
        end
        if parameters.verbose        
          puts "Command: EvaluateExpression #{pipeline_id} #{self.object_id} #{self.expr}" 
        end
        puts "\nEvaluating expression...\n\n"

        begin
          result = client.evaluate_expression(pipeline_id, object_id, expr)
          puts result
        rescue => e
          warn "Unable to evaluate expression: #{e.message}"
          warn e.backtrace.inspect if parameters.trace
        end
      end
    end
  end
end

