require 'rubygems'
require 'json'
require 'set'
require 'date'
require 'time'
require 'amazon/datapipeline/constants'

#
# All the classes here faciliate json serialization/deserialization
# of pipeline definition and translation from/to wire format.
#
module Amazon
  module DataPipeline
    class FieldValue
      REF_KEY = "ref"

      attr_reader :stringValue
      attr_reader :refValue
      def initialize(string, ref)
        raise MalformedObjectError, "Must pass one of 'string' or 'ref' but not both" unless (string.nil? ^ ref.nil?)
        @stringValue = string
        @refValue = ref
      end

      def to_json(*a)
        unless @stringValue.nil?
          return @stringValue.to_json(*a)
        end

        unless @refValue.nil?
          return { REF_KEY => @refValue }.to_json(*a)
        end
      end

      def self.from_json(value)
        if is_primitive(value)
          return FieldValue.new(value.to_s, nil)
        end

        if value.is_a? Hash
          ref = value[REF_KEY]
          if is_primitive(ref)
            return FieldValue.new(nil, ref.to_s)
          end
          raise MalformedObjectError, "Field value should be primitive or reference. Got #{value.inspect}"
        end

        raise MalformedObjectError, "Field value should be primitive or reference. Got #{value.inspect}"
      end

      def self.is_primitive(v)
        v.is_a? String or v.is_a? Numeric or v.is_a? TrueClass or v.is_a? FalseClass
      end

      def self.is_reference(v)
        v.member?(REF_KEY) and is_primitive(v[REF_KEY])
      end

      def to_wire
        return { Constants::VALUE_STRING => @stringValue } unless @stringValue.nil?
        return { Constants::VALUE_REF => @refValue } unless @refValue.nil?
      end

      def self.from_wire(value)
        return FieldValue.new(value[Constants::VALUE_STRING], nil) if value[Constants::VALUE_STRING]
        return FieldValue.new(nil, value[Constants::VALUE_REF]) if value[Constants::VALUE_REF]
        raise MalformedObjectError, "Field value should be primitive or reference. Got #{value.inspect}"
      end

      def to_s
        { "stringValue" => @stringValue, "refValue" => @refValue }.to_s
      end

      def hash
        @stringValue.hash + @refValue.hash
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        if other.equal?(self)
          return true
        elsif !self.class.equal?(other.class)
          return false
        end
        @refValue == other.refValue and @stringValue == other.stringValue
      end
    end

    class Field
      attr_reader :key, :values

      def initialize(key, values)
        raise MalformedObjectError, "Field key or field values cannot be null." if (key.nil? or values.nil?)
        @key = key
        @values = [*values]
      end

      def to_wire
        @values.map { |v| { Constants::FIELD_KEY => @key}.merge!(v.to_wire) }
      end

      def to_s
        @key + '=' + @values.to_s
      end

      def hash
        @key.hash + @values.hash
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        if other.equal?(self)
          return true
        elsif !self.class.equal?(other.class)
          return false
        end
        @key == other.key and @values == other.values
      end

    end

    class LogicalObject
      attr_reader :fields

      def initialize(fields)
        @fields = fields.to_set
      end

      def to_json(*a)
        Hash[@fields.collect { |field| 
          # if there is only one field value we directly serialize it as a primitive
          if field.values.length == 1
            [field.key, field.values[0]]
          else
            [field.key, field.values]
          end
        }].to_json(*a)
      end

      def self.from_json(fields_hash)
        fields = fields_hash.map { |key,values|
          if values.is_a? Array
            Field.new(key, values.map { |v| FieldValue.from_json(v)})
          else
            Field.new(key, FieldValue.from_json(values))
          end
        }
        LogicalObject.new(fields)
      end

      def to_wire(force=nil)
        if !force
          schedule_start_times = @fields.select {|field| field.key == Constants::START_DATETIME}
          if schedule_start_times.length > 0
            schedule_start_time_record = schedule_start_times[0]
            start_time_value = [*schedule_start_time_record.values][0].stringValue

            date_time_object = DateTime.strptime(start_time_value, "%Y-%m-%dT%H:%M:%S").strftime("%Y-%m-%dT%H:%M:%S")
            epoch_schedule_start_time = Time.parse(date_time_object.to_s).to_i

            unix_yest_time = (Time.now.getgm - 24*60*60).to_i

            if unix_yest_time > epoch_schedule_start_time
              warn "Warn: You are about to create a backfill with scheduleStartTime - #{start_time_value}"
              warn "use --force to proceed"
              exit 1
            end
          end
        end

        id_fields = @fields.select {|field| field.key == Constants::ID}
        if id_fields.length != 1
          raise MalformedObjectError, "There must be exactly one id field. Found: #{id_fields.inspect} for #{to_json}"
        end

        id_field = id_fields[0]
        id = [*id_field.values]
        if id.length != 1 or id[0].stringValue.nil?
          raise MalformedObjectError, "There must be exactly one value for id field. Found: #{id_field.inspect}"
        end

        name_fields = @fields.select {|field| field.key == Constants::NAME}
        if name_fields.length > 1
          raise MalformedObjectError, "There must be exactly one value for name field. Found: #{name_fields.inspect}"
        end

        # Populate with value of id if no name present.
        if name_fields.length == 0
          name_fields = id_fields
        end

        name_field = name_fields[0]
        names = [*name_field.values]

        other_fields = @fields.reject {|field| (field.key == Constants::NAME) || (field.key == Constants::ID)}
        { Constants::NAME => names[0].stringValue,
          Constants::ID => id[0].stringValue,
          Constants::FIELD_LIST => other_fields.map { |v| v.to_wire }.flatten }
      end

      def self.from_wire(pipeline_object)
        fields = Array.new
        fields << Field.new(Constants::NAME, [FieldValue.new(pipeline_object[Constants::NAME], nil)])
        fields << Field.new(Constants::ID, [FieldValue.new(pipeline_object[Constants::ID], nil)])

        field_map = Hash.new{|h,k| h[k] = []}
        pipeline_object[Constants::FIELD_LIST].each do |field|
          key = field[Constants::FIELD_KEY]
          field_map[key] << FieldValue.from_wire(field)
        end
        field_map.map { |key, values| fields << Field.new(key, values) }

        LogicalObject.new(fields)
      end

      def hash
        @fields.hash
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        if other.equal?(self)
          return true
        elsif !self.class.equal?(other.class)
          return false
        end
        @fields == other.fields
      end
    end

    class Pipeline
      OBJECTS_KEY = 'objects'

      attr_reader :objects
      def self.get_pipeline(file)
        contents = file.read
        objects_hash = JSON.parse(contents)
        from_json(objects_hash)
      end

      def initialize(objects)
        @objects = objects.to_set
      end

      def to_json(*a)
        { OBJECTS_KEY => @objects.to_a }.to_json(*a)
      end

      def self.from_json(objects_hash)
        objects = objects_hash[OBJECTS_KEY].map { |fields_hash| LogicalObject.from_json fields_hash}
        Pipeline.new objects
      end

      def to_wire(force=nil)
        @objects.map { |obj| obj.to_wire(force) }
      end

      def self.from_wire(pipeline_objects)
        Pipeline.new pipeline_objects.map { |obj| LogicalObject.from_wire(obj) }
      end

      def hash
        @objects.hash
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        if other.equal?(self)
          return true
        elsif !self.class.equal?(other.class)
          return false
        end
        @objects == other.objects
      end
    end

    class MalformedObjectError < StandardError; end
  end
end
