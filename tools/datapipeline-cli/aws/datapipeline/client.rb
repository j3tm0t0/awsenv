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
  class DataPipeline

    class Client < Core::JSONClient

      define_client_methods('2012-10-29')

      ## client methods ##

      # @!method activate_pipeline(options = {})
      # Calls the ActivatePipeline API operation.
      # @param [Hash] options
      #   * +:pipeline_id+ - *required* - (String)
      # @return [Core::Response]

      # @!method create_pipeline(options = {})
      # Calls the CreatePipeline API operation.
      # @param [Hash] options
      #   * +:unique_id+ - *required* - (String)
      #   * +:description+ - (String)
      #   * +:name+ - *required* - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +pipelineId+ - (String)

      # @!method delete_pipeline(options = {})
      # Calls the DeletePipeline API operation.
      # @param [Hash] options
      #   * +:pipeline_id+ - *required* - (String)
      # @return [Core::Response]

      # @!method describe_objects(options = {})
      # Calls the DescribeObjects API operation.
      # @param [Hash] options
      #   * +:marker+ - (String)
      #   * +:object_ids+ - *required* - (Array<String>)
      #   * +:pipeline_id+ - *required* - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +hasMoreResults+ - (Boolean)
      #   * +marker+ - (String)
      #   * +pipelineObjects+ - (Array<Hash>)
      #     * +fields+ - (Array<Hash>)
      #       * +key+ - (String)
      #       * +stringValue+ - (String)
      #       * +refValue+ - (String)
      #     * +name+ - (String)
      #     * +id+ - (String)

      # @!method describe_pipelines(options = {})
      # Calls the DescribePipelines API operation.
      # @param [Hash] options
      #   * +:pipeline_ids+ - *required* - (Array<String>)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +pipelineDescriptionList+ - (Array<Hash>)
      #     * +fields+ - (Array<Hash>)
      #       * +key+ - (String)
      #       * +stringValue+ - (String)
      #       * +refValue+ - (String)
      #     * +name+ - (String)
      #     * +pipelineId+ - (String)
      #     * +description+ - (String)

      # @!method get_pipeline_definition(options = {})
      # Calls the GetPipelineDefinition API operation.
      # @param [Hash] options
      #   * +:pipeline_id+ - *required* - (String)
      #   * +:version+ - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +pipelineObjects+ - (Array<Hash>)
      #     * +fields+ - (Array<Hash>)
      #       * +key+ - (String)
      #       * +stringValue+ - (String)
      #       * +refValue+ - (String)
      #     * +name+ - (String)
      #     * +id+ - (String)

      # @!method poll_for_task(options = {})
      # Calls the PollForTask API operation.
      # @param [Hash] options
      #   * +:worker_group+ - (String)
      #   * +:hostname+ - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +taskObject+ - (Hash)
      #     * +taskId+ - (String)
      #     * +attemptId+ - (String)
      #     * +logUri+ - (String)
      #     * +preconditions+ - (Array<Hash>)
      #       * +fields+ - (Array<Hash>)
      #         * +key+ - (String)
      #         * +stringValue+ - (String)
      #         * +refValue+ - (String)
      #       * +name+ - (String)
      #       * +id+ - (String)
      #     * +pipelineId+ - (String)
      #     * +pipelineObject+ - (Hash)
      #       * +fields+ - (Array<Hash>)
      #         * +key+ - (String)
      #         * +stringValue+ - (String)
      #         * +refValue+ - (String)
      #       * +name+ - (String)
      #       * +id+ - (String)
      #     * +instanceObjectId+ - (String)
      #     * +inputConnectors+ - (Array<Hash>)
      #       * +fields+ - (Array<Hash>)
      #         * +key+ - (String)
      #         * +stringValue+ - (String)
      #         * +refValue+ - (String)
      #       * +name+ - (String)
      #       * +id+ - (String)
      #     * +outputConnectors+ - (Array<Hash>)
      #       * +fields+ - (Array<Hash>)
      #         * +key+ - (String)
      #         * +stringValue+ - (String)
      #         * +refValue+ - (String)
      #       * +name+ - (String)
      #       * +id+ - (String)

      # @!method list_pipelines(options = {})
      # Calls the ListPipelines API operation.
      # @param [Hash] options
      #   * +:marker+ - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +marker+ - (String)
      #   * +hasMoreResults+ - (Boolean)
      #   * +pipelineIdList+ - (Array<Hash>)
      #     * +name+ - (String)
      #     * +id+ - (String)

      # @!method put_pipeline_definition(options = {})
      # Calls the PutPipelineDefinition API operation.
      # @param [Hash] options
      #   * +:pipeline_objects+ - *required* - (Array<Hash>)
      #     * +:fields+ - *required* - (Array<Hash>)
      #       * +:key+ - *required* - (String)
      #       * +:string_value+ - (String)
      #       * +:ref_value+ - (String)
      #     * +:name+ - *required* - (String)
      #     * +:id+ - *required* - (String)
      #   * +:pipeline_id+ - *required* - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +validationErrors+ - (Array<Hash>)
      #     * +errors+ - (Array<String>)
      #     * +id+ - (String)
      #   * +errored+ - (Boolean)

      # @!method query_objects(options = {})
      # Calls the QueryObjects API operation.
      # @param [Hash] options
      #   * +:marker+ - (String)
      #   * +:query+ - (Hash)
      #     * +:selectors+ - (Array<Hash>)
      #       * +:field_name+ - (String)
      #       * +:operator+ - (Hash)
      #         * +:values+ - (Array<String>)
      #         * +:type+ - (String)
      #   * +:sphere+ - *required* - (String)
      #   * +:pipeline_id+ - *required* - (String)
      #   * +:limit+ - (Integer)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +hasMoreResults+ - (Boolean)
      #   * +ids+ - (Array<String>)
      #   * +marker+ - (String)

      # @!method report_task_progress(options = {})
      # Calls the ReportTaskProgress API operation.
      # @param [Hash] options
      #   * +:task_id+ - *required* - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +canceled+ - (Boolean)

      # @!method report_task_runner_heartbeat(options = {})
      # Calls the ReportTaskRunnerHeartbeat API operation.
      # @param [Hash] options
      #   * +:task_runner_id+ - *required* - (String)
      #   * +:worker_group+ - (String)
      #   * +:hostname+ - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +terminate+ - (Boolean)

      # @!method set_task_status(options = {})
      # Calls the SetTaskStatus API operation.
      # @param [Hash] options
      #   * +:task_id+ - *required* - (String)
      #   * +:task_status+ - *required* - (String)
      #   * +:error_stack_trace+ - (String)
      #   * +:error_message+ - (String)
      #   * +:error_code+ - (Integer)
      # @return [Core::Response]

      # @!method set_status(options = {})
      # Calls the SetStatus API operation.
      # @param [Hash] options
      #   * +:status+ - *required* - (String)
      #   * +:object_ids+ - *required* - (Array<String>)
      #   * +:pipeline_id+ - *required* - (String)
      # @return [Core::Response]

      # @!method validate_pipeline_definition(options = {})
      # Calls the ValidatePipelineDefinition API operation.
      # @param [Hash] options
      #   * +:pipeline_objects+ - *required* - (Array<Hash>)
      #     * +:fields+ - *required* - (Array<Hash>)
      #       * +:key+ - *required* - (String)
      #       * +:string_value+ - (String)
      #       * +:ref_value+ - (String)
      #     * +:name+ - *required* - (String)
      #     * +:id+ - *required* - (String)
      #   * +:pipeline_id+ - *required* - (String)
      # @return [Core::Response]
      #   The #data method of the response object returns
      #   a hash with the following structure:
      #   * +validationErrors+ - (Array<Hash>)
      #     * +errors+ - (Array<String>)
      #     * +id+ - (String)
      #   * +errored+ - (Boolean)

      ## end client methods ##

    end
  end
end
