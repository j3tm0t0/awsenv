require 'rubygems'
require 'json'
require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/webservice-utils'
require 'amazon/datapipeline/template'
require 'amazon/datapipeline/queries'

module Amazon
  module DataPipeline

    class GetObjectsCommand < Command

      attr_reader :object_ids

      def initialize(name, object_ids)
        super(name)
        @object_ids = object_ids.uniq
        requires_pipeline_id
      end

      def handle_subcommand(command, args)
        super
      end

      def has_attempts?
        !@attempts.empty?
      end

      def get_objects_by_id(client, parameters, object_ids)
        count = 0
        query = Query.new
        query.set_limit(parameters.limit)

        begin
          query.handle_describe(client, parameters.pipeline_id, object_ids) do |objects|
            puts objects.inspect if parameters.trace
            count += objects.size
            puts JSON.pretty_generate Pipeline.from_wire(objects)
          end
        rescue => e
          warn "Unable to retrieve objects. Failed with error: #{e.message}"
          warn e.backtrace.inspect if parameters.trace
        end
        count
      end

      def run(client, parameters)
        puts "Command: GetObjects #{@object_ids}" if parameters.verbose        
        puts "\nGetting requested objects...\n\n"

        count = get_objects_by_id(client, parameters, @object_ids)

        puts "Retrieved #{count} of #{@object_ids.size} objects from the given list: #{@object_ids.join(", ")}"

        if count < @object_ids.size 
          puts "* Some object ids not found.  Please verify."
        end
      end
    end

  end
end

