require 'time'

module Amazon
  module DataPipeline

    class Interval
      attr_accessor :start_date, :end_date

      def initialize
        @start_date = nil
        @end_date = nil
      end

      def with_dates_string(date_range_string)
        dates = date_range_string.split(',')
        if dates.size != 2 then
          raise RuntimeError, "Invalid date interval '#{date_range_string}'"
        end

        #
        #  Just to be safe, always force the time zone to UTC before parsing.
        #
        ENV['TZ'] = 'UTC'

        with_dates(Time.parse(dates[0]), Time.parse(dates[1]))
      end

      def with_dates(start_date, end_date)
        @start_date = start_date.utc.strftime('%Y-%m-%dT%H:%M:%S')
        @end_date = end_date.utc.strftime('%Y-%m-%dT%H:%M:%S')
        self
      end

      def valid?
        !@start_date.nil? && !@end_date.nil?
      end

      def self.nowMinus(days)
        now = Time.now.utc
        Interval.new.with_dates(now - (days * 60 * 60 * 24), now)
      end

      def to_s
        "#{@start_date},#{@end_date}"
      end
    end

    class Query
      attr_accessor :queries, :limit

      def initialize
        @queries = []
        @limit = 25
      end

      def set_limit(limit)
        @limit = limit
      end

      def add_query(selectors)
        @queries << { "selectors" => selectors.flatten }
      end

      def run_query(client, pipeline_id, sphere, &block)
        run(client, pipeline_id, sphere) do |ids|
          block.call(ids);
        end
      end

      def run_describe(client, pipeline_id, sphere, &block)
        run(client, pipeline_id, sphere) do |ids|
          handle_describe(client, pipeline_id, ids, &block)
        end
      end

      def run(client, pipeline_id, sphere)
        #
        #  If no queries were specified, then default to returning
        #  all objects in pipeline via the empty selector.
        #
        add_query([]) if @queries.empty?

        for query in @queries
          marker = ""
          begin
            output = client.query_objects pipeline_id, sphere, query, marker, @limit

            if output['ids'] != nil then
              yield(output['ids'])
            end

            marker = output['marker']
          end while output['hasMoreResults']
        end
      end

      def handle_describe (client, pipeline_id, object_ids)
        marker = nil

        begin
          output = client.describe_objects(pipeline_id, object_ids, marker)
          yield(output["pipelineObjects"]) if block_given?

          marker = output["marker"]
        end while output["hasMoreResults"]
      end

    end

    class ListRunQuery < Query
      def initialize
        super
        @states = []
        @start_interval = nil
        @schedule_interval = nil
      end

      def to_s() 
        str = ""
        str << "  --status  #{@states.join(",")}\n" if has_states?
        str << "  --start-interval     #{@start_interval.to_s}\n" if has_valid_start_interval?
        str << "  --schedule-interval  #{@schedule_interval.to_s}\n" if has_valid_schedule_interval?
        str
      end
                                            
      def valid?
        has_states? ||
          has_valid_start_interval? ||
          has_valid_schedule_interval?
      end

      def has_states?
        !@states.empty?
      end

      def has_valid_start_interval?
        !@start_interval.nil? && @start_interval.valid?
      end

      def has_valid_schedule_interval?
        !@schedule_interval.nil? && @schedule_interval.valid?
      end

      def add_state(state)
        @states << state
        @states.uniq!
      end

      def add_states(states)
        @states += states
        @states.uniq!
      end

      def set_start_interval(start_interval)
        @start_interval = start_interval
      end

      def set_schedule_interval(schedule_interval)
        @schedule_interval = schedule_interval
      end

      def add_interval_selector(fieldName, interval)
        selectors = []
        selectors << {
          "fieldName" => fieldName,
          "operator" => {
            "type" => "BETWEEN",
            "values" => [interval.start_date, interval.end_date]
          }
        }

        selectors
      end

      def build_queries
        if !self.valid?
          puts "Query is malformed with\n#{self.to_s}"
          exit 1
        end

        selectors = []
        selectors << add_interval_selector("@actualStartTime", @start_interval) if has_valid_start_interval?
        selectors << add_interval_selector("@scheduledStartTime", @schedule_interval) if has_valid_schedule_interval?

        selectors << {
          "fieldName" => "@sphere",
          "operator" => {
            "type" => "EQ",
            "values" => ["INSTANCE"]
          }
        }

        if @states.empty? then
          add_query(selectors)
        else
          for state in @states.flatten
            new_selectors = selectors.dup
            new_selectors << {
              "fieldName" => "@status",
              "operator" => {
                "type" => "EQ",
                "values" => [state]
              }
            }
            add_query(new_selectors)
          end
        end
      end
    end

  end
end
