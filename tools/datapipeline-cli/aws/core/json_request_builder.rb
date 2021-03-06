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

module AWS
  module Core

    # @private
    class JSONRequestBuilder

      def initialize target_prefix, operation
        @x_amz_target = target_prefix + operation[:name]
        @grammar = OptionGrammar.customize(operation[:inputs])
      end

      def populate_request request, options
        request.headers["content-type"] = "application/x-amz-json-1.1"
        request.headers["x-amz-target"] = @x_amz_target
        request.body = @grammar.to_json(options)
      end

    end

  end
end
