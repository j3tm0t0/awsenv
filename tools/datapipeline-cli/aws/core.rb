# Copyright 2011-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require 'aws/version'
require 'aws/core/autoloader'

# AWS is the root module for all of the Amazon Web Services.  It is also
# where you can configure you access to AWS.
#
# = Supported Services
#
# The currently supported services are:
#
# * {AWS::DataPipeline}
#
# You call {AWS.config} with a hash of options to configure your
# access to the Amazon Web Services.
#
# At a minimum you need to set your access credentials. See {AWS.config}
# for additional configuration options.
#
#    AWS.config(
#      :access_key_id => 'ACCESS_KEY_ID',
#      :secret_access_key => 'SECRET_ACCESS_KEY')
#
module AWS

  register_autoloads(self) do
    autoload :Errors, 'errors'
  end

  module Core

    AWS.register_autoloads(self) do

      autoload :AsyncHandle,               'async_handle'
      autoload :Cacheable,                 'cacheable'
      autoload :Client,                    'client'
      autoload :Collection,                'collection'
      autoload :Configuration,             'configuration'
      autoload :CredentialProviders,       'credential_providers'
      autoload :Data,                      'data'
      autoload :IndifferentHash,           'indifferent_hash'
      autoload :Inflection,                'inflection'

      autoload :JSONClient,                'json_client'
      autoload :JSONRequestBuilder,        'json_request_builder'
      autoload :JSONResponseParser,        'json_response_parser'

      autoload :LazyErrorClasses,          'lazy_error_classes'
      autoload :LogFormatter,              'log_formatter'
      autoload :MetaUtils,                 'meta_utils'
      autoload :Model,                     'model'
      autoload :Naming,                    'naming'
      autoload :OptionGrammar,             'option_grammar'
      autoload :PageResult,                'page_result'
      autoload :Policy,                    'policy'

      autoload :Resource,                  'resource'
      autoload :ResourceCache,             'resource_cache'
      autoload :Response,                  'response'
      autoload :ResponseCache,             'response_cache'

      autoload :ServiceInterface,          'service_interface'
      autoload :Signer,                    'signer'
      autoload :UriEscape,                 'uri_escape'

    end

    module Options
      AWS.register_autoloads(self) do
        autoload :XMLSerializer, 'xml_serializer'
        autoload :Validator, 'validator'
      end
    end

    module Signature
      AWS.register_autoloads(self) do
        autoload :Version4,      'version_4'
      end
    end

    module XML
      AWS.register_autoloads(self) do
        autoload :Parser,     'parser'
        autoload :Grammar,    'grammar'
        autoload :Stub,       'stub'
        autoload :Frame,      'frame'
        autoload :RootFrame,  'root_frame'
        autoload :FrameStack, 'frame_stack'
      end

      module SaxHandlers
        AWS.register_autoloads(self, 'aws/core/xml/sax_handlers') do
          autoload :Nokogiri, 'nokogiri'
          autoload :REXML,    'rexml'
        end
      end

    end

    module Http
      AWS.register_autoloads(self) do
        autoload :Handler,         'handler'
        autoload :NetHttpHandler,  'net_http_handler'
        autoload :HTTPartyHandler, 'httparty_handler' # non-standard inflection
        autoload :Request,         'request'
        autoload :Response,        'response'
      end
    end

  end

  # the http party handler should still be accessible from its old namespace
  module Http
    AWS.register_autoloads(self, 'aws/core/http') do
      autoload :HTTPartyHandler, 'httparty_handler'
    end
  end

  class << self

    # @private
    @@config = nil

    # The global configuration for AWS.  Generally you set your prefered
    # configuration operations once after loading the aws-sdk gem.
    #
    #   AWS.config({
    #     :access_key_id => 'ACCESS_KEY_ID',
    #     :secret_access_key => 'SECRET_ACCESS_KEY',
    #     :simple_db_endpoint => 'sdb.us-west-1.amazonaws.com',
    #     :max_retries => 2,
    #   })
    #
    # When using AWS classes they will always default to use configuration
    # values defined in {AWS.config}.
    #
    #   AWS.config(:max_retries => 2)
    #
    #   datapipeline = AWS::DataPipeline.new
    #   datapipline.config.max_retries #=> 2
    #
    # @param [Hash] options
    #
    # @option options [String] :access_key_id AWS access key id
    #   credential.
    #
    # @option options [String] :secret_access_key AWS secret access
    #   key credential.
    #
    # @option options [String,nil] :session_token AWS secret token
    #   credential.
    #
    # @option options [String] :datapipeline_endpoint ('datapipeline.us-east-1.amazonaws.com') The
    #   service endpoint for Amazon DataPipeline.
    #
    # @option options [Object] :http_handler (AWS::Core::Http::NetHttpHandler)
    #   The http handler that sends requests to AWS.
    #
    # @option options [Integer] :http_idle_timeout (60) The number of seconds
    #   a persistent connection is allowed to sit idle before it should no
    #   longer be used.
    #
    # @option options [Integer] :http_open_timeout (15) The number of seconds
    #   before the +:http_handler+ should timeout while trying to open a new
    #   HTTP sesssion.
    #
    # @option options [Integer] :http_read_timeout (60) The number of seconds
    #   before the +:http_handler+ should timeout while waiting for a HTTP
    #   response.
    #
    # @option options [Boolean] :http_wire_trace (false) When +true+, the
    #   http handler will log all wire traces to the +:logger+.  If a
    #   +:logger+ is not configured, then wire traces will be sent to
    #   standard out.
    #
    # @option options [Logger,nil] :logger (nil) A logger to send
    #   log messages to.  Here is an example that logs to standard out.
    #
    #     require 'logger'
    #     AWS.config(:logger => Logger.new($stdout))
    #
    # @option options [Symbol] :log_level (:info) The level log messages are
    #   sent to the logger with (e.g. +:notice+, +:info+, +:warn+,
    #   +:debug+, etc).
    #
    # @option options [Object] :log_formatter The log formatter is responsible
    #   for building log messages from responses. You can quickly change
    #   log formats by providing a pre-configured log formatter.
    #
    #     AWS.config(:log_formatter => AWS::Core::LogFormatter.colored)
    #
    #   Here is a list of pre-configured log formatters:
    #
    #   * +AWS::Core::LogFormatter.default+
    #   * +AWS::Core::LogFormatter.short+
    #   * +AWS::Core::LogFormatter.debug+
    #   * +AWS::Core::LogFormatter.colored+
    #
    #   You can also create an instance of AWS::Core::LogFormatter
    #   with a custom log message pattern. See {Core::LogFormatter} for
    #   a complete list of pattern substituions.
    #
    #     pattern = "[AWS :operation :duration] :error_message"
    #     AWS.config(:log_formatter => AWS::Core::LogFormatter.new(pattern))
    #
    #   Lastly you can pass any object that responds to +#format+ accepting
    #   and instance of {Core::Response} and returns a string.
    #
    # @option options [Integer] :max_retries (3) The maximum number of times
    #   service errors (500) should be retried.  There is an exponential
    #   backoff in between service request retries, so the more retries the
    #   longer it can take to fail.
    #
    # @option options [String, URI, nil] :proxy_uri (nil) The URI of the proxy
    #    to send service requests through.  You can pass a URI object or a
    #    URI string:
    #
    #       AWS.config(:proxy_uri => 'https://user:password@my.proxy:443/path?query')
    #
    # @option options [OpenSSL::PKey::RSA, String] :s3_encryption_key (nil)
    #   If this is set, AWS::S3::S3Object #read and #write methods will always
    #   perform client-side encryption with this key. The key can be overridden
    #   at runtime by using the :encryption_key option.  A value of nil
    #   means that client-side encryption will not be used.
    #
    # @option options [CredentialProviders::Provider] :credential_provider (AWS::Core::CredentialProviders::DefaultProvider.new)
    #   Returns the credential provider.  The default credential provider
    #   attempts to check for statically assigned credentials, ENV credentials
    #   and credentials in the metadata service of EC2.
    #
    # @option options [String] :ssl_ca_file The path to a CA cert bundle in
    #   PEM format.
    #
    #   If +:ssl_verify_peer+ is +true+ (the default) this bundle will be
    #   used to validate the server certificate in each HTTPS request.
    #   The AWS SDK for Ruby ships with a CA cert bundle, which is the
    #   default value for this option.
    #
    # @option options [String] :ssl_ca_path (nil)
    #   The path the a CA cert directory.
    #
    # @option options [Boolean] :ssl_verify_peer (true) When +true+
    #   the HTTP handler validate server certificates for HTTPS requests.
    #
    #   This option should only be disabled for diagnostic purposes;
    #   leaving this option set to +false+ exposes your application to
    #   man-in-the-middle attacks and can pose a serious security
    #   risk.
    #
    # @option options [Boolean] :stub_requests (false) When +true+ requests
    #   are not sent to AWS, instead empty reponses are generated and
    #   returned to each service request.
    #
    # @option options [Boolean] :use_ssl (true) When +true+, all requests
    #   to AWS are sent using HTTPS instead vanilla HTTP.
    #
    # @option options [String] :user_agent_prefix (nil) A string prefix to
    #   append to all requets against AWS services.  This should be set
    #   for clients and applications built ontop of the aws-sdk gem.
    #
    # @return [Core::Configuration] Returns the new configuration.
    #
    def config options = {}
      @@config ||= Core::Configuration.new
      @@config = @@config.with(options) unless options.empty?
      @@config
    end

    # @note Memoization is currently only supported for the EC2 APIs;
    #   other APIs are unaffected by the status of memoization.  To
    #   protect your code from future changes in memoization support,
    #   you should not enable memoization while calling non-EC2 APIs.
    #
    # Starts memoizing service requests made in the current thread.
    # See {memoize} for a full discussion of the memoization feature.
    # This has no effect if memoization is already enabled.
    def start_memoizing
      Thread.current[:aws_memoization] ||= {}
      nil
    end

    # @note Memoization is currently only supported for the EC2 APIs;
    #   other APIs are unaffected by the status of memoization.  To
    #   protect your code from future changes in memoization support,
    #   you should not enable memoization while calling non-EC2 APIs.
    #
    # Stops memoizing service requests made in the current thread.
    # See {memoize} for a full discussion of the memoization feature.
    # This has no effect if memoization is already disabled.
    def stop_memoizing
      Thread.current[:aws_memoization] = nil
    end

    # @note Memoization is currently only supported for the EC2 APIs;
    #   other APIs are unaffected by the status of memoization.  To
    #   protect your code from future changes in memoization support,
    #   you should not enable memoization while calling non-EC2 APIs.
    #
    # @return [Boolean] True if memoization is enabled for the current
    #   thread.  See {memoize} for a full discussion of the
    #   memoization feature.
    def memoizing?
      !Thread.current[:aws_memoization].nil?
    end

    # @note Memoization is currently only supported for the EC2 APIs;
    #   other APIs are unaffected by the status of memoization.  To
    #   protect your code from future changes in memoization support,
    #   you should not enable memoization while calling non-EC2 APIs.
    #
    # Enables memoization for the current thread, within a block.
    # Memoization lets you avoid making multiple requests for the same
    # data by reusing the responses which have already been received.
    # For example, consider the following code to get the most
    # recently launched EC2 instance:
    #
    #  latest = ec2.instances.sort_by(&:launch_time).last
    #
    # The above code would make N+1 requests (where N is the number of
    # instances in the account); iterating the collection of instances
    # is one request, and +Enumerable#sort_by+ calls
    # {AWS::EC2::Instance#launch_time} for each instance, causing
    # another request per instance.  We can rewrite the code as
    # follows to make only one request:
    #
    #  latest = AWS.memoize do
    #    ec2.instances.sort_by(&:launch_time).last
    #  end
    #
    # Iterating the collection still causes a request, but each
    # subsequent call to {AWS::EC2::Instance#launch_time} uses the
    # results from that first request rather than making a new request
    # for the same data.
    #
    # While memoization is enabled, every response that is received
    # from the service is retained in memory.  Therefore you should
    # use memoization only for short-lived blocks of code that make
    # relatively small numbers of requests.  The cached responses are
    # used in two ways while memoization is enabled:
    #
    # 1. Before making a request, the SDK checks the cache for a
    #    response to a request with the same signature (credentials,
    #    service endpoint, operation name, and parameters).  If such a
    #    response is found, it is used instead of making a new
    #    request.
    #
    # 2. Before retrieving data for an attribute of a resource
    #    (e.g. {AWS::EC2::Instance#launch_time}), the SDK attempts to
    #    find a cached response that contains the requested data.  If
    #    such a response is found, the cached data is returned instead
    #    of making a new request.
    #
    # When memoization is disabled, all previously cached responses
    # are discarded.
    def memoize
      return yield if memoizing?
      begin
        start_memoizing
        yield if block_given?
      ensure
        stop_memoizing
      end
    end

    # @private
    def resource_cache
      if memoizing?
        Thread.current[:aws_memoization][:resource_cache] ||=
          Core::ResourceCache.new
      end
    end

    # @private
    def response_cache
      if memoizing?
        Thread.current[:aws_memoization][:response_cache] ||=
          Core::ResponseCache.new
      end
    end

    # Causes all requests to return empty responses without making any
    # requests against the live services.  This does not attempt to
    # mock the services.
    # @return [nil]
    def stub!
      config(:stub_requests => true)
      nil
    end

  end
end
