require 'amazon/datapipeline/webservice-client'
require 'amazon/datapipeline/queries'

module Amazon
  module DataPipeline

    class ListRunsCommand < Command
      def initialize(name)
        super(name)

        @states = []
        @start_interval = nil
        @schedule_interval = nil

        requires_pipeline_id
      end

      def handle_subcommand(command, args)
        case command
        when '--status'
          @states += args.split(',')
        when '--running'
          @states += ["RUNNING", "WAITING_FOR_RUNNER"]
        when '--failed'
          @states << "FAILED"
        when '--start-interval'
          @start_interval = Interval.new.with_dates_string(args)
        when '--schedule-interval'
          @schedule_interval = Interval.new.with_dates_string(args)
        else
          super
        end
      end

      def create_query
        query = ListRunQuery.new
        query.add_states @states
        query
      end

      def show_start_interval_help(num_prev_days)
        puts "For the last #{num_prev_days} days of actual runs, use:"
        puts "  --start-interval #{Interval.nowMinus(num_prev_days)}"
      end

      def show_schedule_interval_help(num_prev_days)
        puts "For the last #{num_prev_days} days of scheduled runs, use:"
        puts "  --schedule-interval #{Interval.nowMinus(num_prev_days)}"
      end

      def put_object(object)
        object_fields = {}
        object_fields["name"] = object["name"]
        object_fields["@id"] = object["id"]
        for field in object["fields"] do
          object_fields[field["key"]] = field["stringValue"] if field["stringValue"]
          object_fields[field["key"]] = field["refValue"] if field["refValue"]
        end
        object_fields
      end

      def get_object_list_for_query(client, parameters, query)
        query.set_limit(parameters.limit)
        query.build_queries
        puts "\nQuery: #{query}" if parameters.trace

        object_list = []
        query.run_describe(client, parameters.pipeline_id, "INSTANCE") do |objects|
          for object in objects
            ret_object = put_object object

            start = ret_object['@scheduledStartTime']
            if start
              object_list << ret_object
            end
          end
        end
        object_list
      end

      def run(client, parameters)
        puts "Command: List Runs:" if parameters.verbose

        #
        #  Cut off their listings after this many objects.
        #
        cutoff = 1000
        num_prev_days = 4

        if @start_interval && !@start_interval.valid?
          puts "The #{self.name} command received an invalid --start-interval."
          show_start_interval_help(num_prev_days)
          exit 1
        end

        if @schedule_interval && !@schedule_interval.valid?
          puts "The #{self.name} command received an invalid --schedule-interval."
          show_schedule_interval_help(num_prev_days)
          exit 1
        end

        #
        #  If no start nor schedule interval is given, list the 100 most
        #  recently scheduled or started runs over the last num_prev_days
        #  days.
        #
        object_list = []
        if !@start_interval && !@schedule_interval
          puts "The #{self.name} command is fetching the last #{num_prev_days} days of pipeline runs."
          puts "If this takes too long, use --help for how to specify a different"
          puts "interval with --start-interval or --schedule-interval."

          cutoff = 100
          range = Interval.nowMinus(num_prev_days)
          start_query = create_query
          start_query.set_start_interval range

          object_list += get_object_list_for_query(client, parameters, start_query)
        else
          #
          #  Construct the users query.
          #
          query = create_query 
          query.set_start_interval @start_interval if @start_interval
          query.set_schedule_interval @schedule_interval if @schedule_interval
          object_list += get_object_list_for_query(client, parameters, query)
        end

        #
        #  This is a hack to simulate a call that returns the last cutoff
        #  many objects by reversed scheduled date.
        #
        parsed_objects = {}
        drop_count = [0, object_list.size - cutoff].max
        sorted_list = object_list.sort_by {|obj| obj['@scheduledStartTime'] }

        #
        #  No need to worry about duplicate entries as they are stored
        #  into hashed here.
        #
        sorted_list.drop(drop_count).each do |object|
          start = object['@scheduledStartTime']
          parsed_objects[start] ||= {}
          parsed_objects[start][object['name']] = object
        end

        puts "Displaying pipelines runs where:\n#{@query.to_s}" if parameters.verbose
        puts parsed_objects.inspect if parameters.trace

        if parsed_objects.empty? then
          puts "No pipeline runs found where\n"
        else
          pipeline_name = (client.describe_pipelines [parameters.pipeline_id])[0]["name"]

          puts
          str1 = "       %-50.50s  %-19.19s  %-23.23s" % ["Name", "Scheduled Start", "Status"]
          str2 = "       %-50.50s  %-19.19s  %-19.19s" % ["ID", "Started", "Ended"]
          puts "#{str1}\n#{str2}\n#{"-" * str1.length}"

          index = 0
          show_status_changed = false
          for interval in parsed_objects.keys.sort
            for name in parsed_objects[interval].keys.sort
              object_fields = parsed_objects[interval][name]

              index += 1
              object_id = object_fields['@id']
              logical_name = object_fields['logicalParent']
              scheduled_start_date = object_fields['@scheduledStartTime']
              status = object_fields['@status']
              start_date = object_fields['@actualStartTime']
              end_date = object_fields['@actualEndTime']
              status_changing = object_fields.has_key?('@desiredStatus')
              show_status_changed ||= status_changing
              status_changing_indicator = status_changing ? "*" : " "

              str1 = "%4d.  %-50.50s  %-19.19s %1.1s%-23.23s" % [index, logical_name, scheduled_start_date, status_changing_indicator, status]
              str2 = "       %-50.50s  %-19.19s  %-19.19s" % [object_id, start_date, end_date]
              puts "#{str1}\n#{str2}\n\n"
            end
          end
          puts "\nThe '*' symbol indicates that a request to change the status is pending." if show_status_changed
          puts "\nAll times are listed in UTC and all command line input is treated as UTC."

          intro = 0 < drop_count ? "Last" : "Total of"
          puts "\n#{intro} #{index} pipeline runs shown from pipeline named '#{pipeline_name}' where\n"
        end

        #
        #  Print out the query for the user to inspect.
        #
        if !@start_interval && !@schedule_interval
          puts start_query.to_s
        else
          puts query.to_s
        end
      end
    end

  end
end
