require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/webservice-utils'
require 'amazon/datapipeline/queries'

module Amazon
  module DataPipeline

    class SetStatusObjectsCommand < Command
      def initialize(name, object_ids, status)
        super(name)
        @object_ids = object_ids.uniq
        @status = status
        requires_pipeline_id
      end

      def run(client, parameters)
        puts "Command: SetStatusObjects '#{@status}' for objects: #{@object_ids.join(", ")}" if parameters.verbose
        puts "Changing status to '#{@status}' for objects: #{@object_ids.join(", ")}"

        if !@object_ids.empty?
          begin
            client.set_status(parameters.pipeline_id, @object_ids, @status)
            puts "Object status set."
          rescue => e
            warn "Failed to set object status with error #{e.message}"
            warn e.backtrace if parameters.trace
            exit 1
          end
        end
      end
    end

    class RerunObjectsCommand < SetStatusObjectsCommand
      def initialize(object_ids)
        super("--rerun", object_ids, "rerun")
      end

      def run(client, parameters)
        puts "Command: RerunObjects objects in pipeline: #{parameters.pipeline_id}" if parameters.verbose
        super
      end
    end

    class CancelObjectsCommand < SetStatusObjectsCommand
      def initialize(object_ids)
        super("--cancel", object_ids, "try_cancel")
      end

      def run(client, parameters)
        puts "Command: CancelObjects objects in pipeline: #{parameters.pipeline_id}" if parameters.verbose
        super
      end
    end
    
    class MarkFinishedObjectsCommand < SetStatusObjectsCommand
      def initialize(object_ids)
        super("--mark-finished", object_ids, "mark_finished")
      end

      def run(client, parameters)
        puts "Command: Mark objects as finished in pipeline: #{parameters.pipeline_id}" if parameters.verbose
        super
      end
    end

    class PauseObjectsCommand < SetStatusObjectsCommand
      def initialize(object_ids)
        super("--pause", object_ids, "pause")
      end

      def run(client, parameters)
        puts "Command: PauseObjects in pipeline: #{parameters.pipeline_id}" if parameters.verbose
        super
      end
    end

    class ResumeObjectsCommand < SetStatusObjectsCommand
      def initialize(object_ids)
        super("--resume", object_ids, "resume")
      end

      def run(client, parameters)
        puts "Command: ResumeObjects objects in pipeline: #{parameters.pipeline_id}" if parameters.verbose
        super
      end
    end

  end
end
