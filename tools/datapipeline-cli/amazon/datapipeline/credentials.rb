require 'rubygems'
require 'json'


module Amazon
  module DataPipeline
    class Credentials
      # Parse a credentials json file or process a set of parameters
      def initialize
      end

      def parse_credentials(credentials, options = Hash.new)
        conversions = [
                       # Now the current ones
                       [:aws_access_key, "access-id"],
                       [:aws_secret_key, "private-key"],
                       [:key_pair, "key-pair"], 
                       [:key_pair_file, "key-pair-file"], 
                       [:endpoint, "endpoint"], 
                       [:port, "port"], 
                       [:region, "region"], 
                       [:enable_debugging, "enable-debugging"],
                       [:timeout, "timeout"]
                      ]

        env_options = [
                       ['DATA_PIPELINE_ACCESS_ID',         :aws_access_key],
                       ['DATA_PIPELINE_SECRET_KEY',        :aws_secret_key],
                       ['DATA_PIPELINE_KEY_PAIR',          :key_pair],
                       ['DATA_PIPELINE_KEY_PAIR_FILE',     :key_pair_file],
                       ['DATA_PIPELINE_ENDPOINT',          :endpoint],
                       ['DATA_PIPELINE_REGION',            :region],
                       ['DATA_PIPELINE_ENABLE_DEBUGGING',  :enable_debugging],
                       ['DATA_PIPELINE_TIMEOUT',           :timeout]
                      ]

        for env_key, option_key in env_options do
          if ! options[option_key] && ENV[env_key] then
            options[option_key] = ENV[env_key]
          end
        end

        filename = nil
        if credentials
          #
          #  If specified and valid, utilize the provided credentials file.
          #
          if is_valid_credential_file credentials
            filename = credentials
          else
            puts "Specified credential file '#{credentials}' is not valid."
            puts "Please confirm that the file exists and has correct permissions."
            exit 1
          end
        else
          #
          #  Otherwise, best effort attempt to find a valid credentials file.
          #
          candidates = [
            ENV['DATA_PIPELINE_CREDENTIALS'], 
            File.join(File.dirname(__FILE__), "credentials.json"),
            File.join(ENV['HOME'], ".credentials.json"), 
            File.join(ENV['HOME'], "credentials.json")
          ]

          filename = candidates.find do |name|
            is_valid_credential_file name
          end

          unless filename 
            puts "Unable to find a valid credentials file in the following locations:"
            candidates.each do |file|
              puts "  #{file}"
            end
            exit 1
          end
        end

        if filename
          begin
            credentials_hash = JSON.parse(File.read(filename))
            for option_key, credentials_key in conversions do
              if credentials_hash[credentials_key] && !options[option_key] then
                options[option_key] = credentials_hash[credentials_key]
              end
            end
          rescue => e
            raise RuntimeError, "Unable to parse #{filename}: #{e.message}"
          end
        else
          puts "Unable to find a valid credentials file."
          exit 1
        end

        if options[:timeout] != nil
          ti = options[:timeout].to_i
          raise ArgumentError, "timeout must be non-negative integer" if ti.to_s != options[:timeout].to_s || ti < 0
          options[:timeout] = ti
        end

        options
      end

      def is_valid_credential_file (name)
        !name.nil? && File.exist?(name) && File.file?(name) && File.readable?(name)
      end
    end
  end
end
