require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/queries'

module Amazon
  module DataPipeline

    class ListPipelinesCommand < Command
      def initialize(name)
        super(name)
      end

      def paginate(client, limit, &block)
        pipelines = client.list_pipelines.values.flatten.each_slice(limit) do |pipeline_ids|
          pipeline_descriptions = client.describe_pipelines pipeline_ids
          for pipeline_description in pipeline_descriptions do
            block.call(pipeline_description)
          end
        end
      end

      def run(client, parameters)
        puts "Command: List Pipelines:" if parameters.verbose

        str = "       %-30.30s  %-35.35s  %-16.16s %-25s" % ["Name", "Id", "State", "UserId"]
        puts str << "\n" << "-" * str.length

        count = 0
        marker = ""
        begin
          output = client.list_pipelines(marker)
          pipeline_ids = get_pipeline_ids(output)
          count += describe(client, pipeline_ids, count)

          marker = output['marker']
        end while output['hasMoreResults']

        puts "\nTotal of #{count} pipelines."
      end

      def describe(client, pipeline_ids, offset)
        count = 0
        client.describe_pipelines(pipeline_ids).each do |pipeline_description|
          count += 1
          name = pipeline_description["name"]
          id = pipeline_description["pipelineId"]
          state = pipeline_description["@pipelineState"]
          user_id = pipeline_description["@userId"]
          puts "%4d.  %-30.30s  %-35.35s  %-16.16s %-20.20s" % [offset + count, name, id, state, user_id]
        end
         count
      end

      def get_pipeline_ids(output)
        ids = []

        output['pipelineIdList'].each do |idname|
          ids << idname['id']
        end

        ids
      end
    end
  end
end
