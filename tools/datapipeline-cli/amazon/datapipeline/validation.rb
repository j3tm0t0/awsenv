require 'amazon/datapipeline/constants'

module Amazon
  module DataPipeline

    class ObjectValidator
      def initialize(object)
        @object = object
        @errors_found = [];

        fields = @object[Constants::FIELD_LIST]
        fields.sort! { |a,b| a[Constants::FIELD_KEY].downcase <=> b[Constants::FIELD_KEY].downcase }

        fields.each do |field|
          if field[Constants::FIELD_KEY] == '@error'
            @errors_found << field[Constants::VALUE_STRING]
          end
        end
      end

      def has_errors?
        0 < get_error_count
      end

      def get_error_count
        @errors_found.length
      end

      def get_error_string
        error_string = ""
        if has_errors? then
          error_string << "Object definition '#{@object[Constants::NAME]}' contains #{get_error_count} validation errors:\n"
          count = 0
          @errors_found.each do |error| 
            count += 1
            error_string << ("%3d.  %s\n" % [count, error.sub(/:/, ':  ')])
          end
          error_string << "\n"
        end
        error_string
      end
    end

    class ObjectsValidator
      def initialize
        @objectValidators = []
      end

      def add(objects)
        objects.sort! { |a,b| a[Constants::NAME].downcase <=> b[Constants::NAME].downcase }
        objects.each do |object|
          @objectValidators << ObjectValidator.new(object)
        end
      end

      def has_errors?
        0 < get_error_count
      end

      def get_error_count
        count = 0
        @objectValidators.each do |validator|
          count += validator.get_error_count
        end
        count
      end

      def get_error_string
        error_string = ""
        if has_errors? then
          @objectValidators.each do |validator|
            error_string << validator.get_error_string
          end
          error_string << "Total of #{get_error_count} validation errors found.\n"
        end
        error_string
      end
    end

    class PipelineValidator
      def initialize(client, verbose)
        @client = client
        @verbose = verbose
      end

      def get_pipeline_state(pipeline_id)
        begin
          (@client.describe_pipelines [pipeline_id])[0]["@pipelineState"]
        rescue => e
          warn e.message
          warn e.backtrace.inspect if @verbose
          exit 1
        end
      end

      def get_warnings(pipeline_id)
          state = get_pipeline_state(pipeline_id)
          warning = "State of pipeline id '#{pipeline_id}' is currently '#{state}'\n"

          case state
          when "ERRORED" then
            warning << "Warning: The specified pipeline contains validation errors."
          when "DEPRECATED" then
            warning << "Warning: The specified pipeline is deprecated."
          end

          warning
      end
    end

  end
end
