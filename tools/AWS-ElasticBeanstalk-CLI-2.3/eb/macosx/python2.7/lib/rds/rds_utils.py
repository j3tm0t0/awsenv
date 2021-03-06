#!/usr/bin/env python
#==============================================================================
# Copyright 2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#       http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions
# and limitations under the License.
#==============================================================================
import logging

from lib.aws.exception import MissingParameterException, InvalidParameterValueException
from lib.elasticbeanstalk.model import ConfigurationOptionSetting, OptionSepcification
from lib.elasticbeanstalk.request import TemplateSource, TemplateSpecification, TemplateSnippet
from lib.rds.exception import RdsDBInstanceNotFoundException
from scli import api_wrapper
from scli.constants import ParameterName, RdsDefault, RdsEndpoint
from scli.resources import CommandType
from scli.parameter import Parameter

log = logging.getLogger('cli')


CommandRequireRdsParameter = [
    CommandType.START,
    CommandType.UPDATE,
]

#-----------------------------------
#     Utility functions
#-----------------------------------

def generate_endpoint(parameter_pool, region, source, force = False):
    parameter_pool.put(Parameter(ParameterName.RdsEndpoint, 
                                 RdsEndpoint[region], 
                                 source))     
    parameter_pool.put(Parameter(ParameterName.RdsSnippetUrl, 
                                 RdsDefault.get_snippet_url(region), 
                                 source))      


def rds_handler(parameter_pool, template_spec, stack_name, option_settings, option_to_remove):
    snippet_url = parameter_pool.get_value(ParameterName.RdsSnippetUrl)
    
    # If not specified or incompatible, skip 
    if not is_rds_snippet_compatible(parameter_pool, stack_name, snippet_url)\
        or not parameter_pool.has(ParameterName.RdsEnabled):
        _remove_all_rds_options(option_settings)
        return None
    
    if parameter_pool.get_value(ParameterName.RdsEnabled):
        _add_rds_extension(parameter_pool, template_spec, option_settings, option_to_remove)
    else:
        _remove_rds_extension(parameter_pool, template_spec, option_settings, option_to_remove)



def is_rds_snippet_compatible(parameter_pool, solution_stack, snippet_url = None):
    if snippet_url is None:
        snippet_url = parameter_pool.get_value(ParameterName.RdsSnippetUrl)
    eb_client = api_wrapper.create_eb_client(parameter_pool)

    app_name = parameter_pool.get_value(ParameterName.ApplicationName)    
    api_wrapper.create_application(parameter_pool, app_name, eb_client = eb_client)
    
    spec = TemplateSpecification(TemplateSource(solution_stack), 
                                 [TemplateSnippet(RdsDefault.SnippetName,
                                                 snippet_url, 
                                                 order = RdsDefault.SnippetAddOrder)])
    try:
        log.info(u'Send request for ValidateConfigurationSettings call.')
        response = eb_client.validate_configuration_settings(application_name = app_name,
                                                             template_specification = spec)
        log.info(u'Received response for ValidateConfigurationSettings call.')
        api_wrapper.log_response(u'ValidateConfigurationSettings', response.result)            
    except MissingParameterException:
        return False
    else:
        log.info(u'Received response for ValidateConfigurationSettings call.')
        api_wrapper.log_response(u'ValidateConfigurationSettings', response.result)            
    
    return True



def is_rds_delete_to_snapshot(parameter_pool, app_name, env_name):
    policy_option = OptionSepcification(RdsDefault.Namespace, 
                                          RdsDefault.OptionNames[ParameterName.RdsDeletionPolicy])
    try:
        policy_setting = api_wrapper.retrieve_configuration_settings(parameter_pool, app_name,
                                                                     env_name = env_name, 
                                                                     options = [policy_option])
    except InvalidParameterValueException:
        return None  # Environment not exist. No RDS instance        

    if len(policy_setting) != 1:
        return None # Option name not found. No RDS instance
   
    return RdsDefault.del_policy_to_bool(policy_setting[0].value) 


def retrieve_rds_instance_property(parameter_pool, env_name):
    #TODO: handling multiple rds instances
    #Search for first RDS instance
    try:
        resources = api_wrapper.retrieve_environment_resources(parameter_pool, env_name)
    except InvalidParameterValueException:
        return None, None # environment not exists
    
    for resource in resources.resources:
        if resource.type == RdsDefault.ResourceType:
            physical_id = resource.physical_resource_id
            logical_id = resource.logical_resource_id
            break
    else:
        return None, None # Cannot find any RDS instance

    try:
        return logical_id, api_wrapper.retrive_rds_instance(parameter_pool, physical_id)
    except RdsDBInstanceNotFoundException:
        return logical_id, None # RDS Instance is 


def has_rds_instance(parameter_pool, env_name):
    #TODO: handling multiple rds instances
    _, rds_property = retrieve_rds_instance_property(parameter_pool, env_name)
    if rds_property is None:
        return False
    else:
        return True


def password_key_name(env_name):
    return env_name + u'_' + ParameterName.RdsMasterPassword


def is_require_rds_parameters(parameter_pool):
    command = parameter_pool.get_value(ParameterName.Command)
    if command in CommandRequireRdsParameter:
        return True
    else:
        return False
   
#-----------------------------------
#     Helper functions
#-----------------------------------

def _add_rds_extension(parameter_pool, template_spec, option_settings, option_to_remove):
    region = parameter_pool.get_value(ParameterName.Region)
    
    #Generate snippet    
    env_name = parameter_pool.get_value(ParameterName.EnvironmentName)
    if not has_rds_instance(parameter_pool, env_name):
        snippet = TemplateSnippet()
        snippet.snippet_name = RdsDefault.SnippetName
        snippet.source_url = RdsDefault.get_snippet_url(region)
        snippet.order = RdsDefault.SnippetAddOrder
        template_spec.template_snippets.append(snippet)
    
    #Add/update option settings
    #TODO: change option_settings to o(1) structure while retain order for output
    for pname in RdsDefault.OptionMinSet:
        if parameter_pool.has(pname) and parameter_pool.get_value(pname) is not None:
            _update_option_setting(option_settings, 
                                   RdsDefault.Namespace, 
                                   RdsDefault.OptionNames[pname], 
                                   parameter_pool.get_value(pname))
    
    _trim_rds_options(option_settings, option_to_remove)


def _remove_rds_extension(parameter_pool, template_spec, option_settings, option_to_remove):
    region = parameter_pool.get_value(ParameterName.Region)
    
    #Generate snippet
    snippet = TemplateSnippet()
    snippet.snippet_name = RdsDefault.SnippetName
    snippet.source_url = RdsDefault.get_snippet_url(region)
    snippet.order = RdsDefault.SnippetRemoveOrder
    template_spec.template_snippets.append(snippet)
    
    #Remove option settings
    for pname in RdsDefault.OptionNames:
        _remove_option_setting(option_settings, 
                               option_to_remove,
                               RdsDefault.Namespace, 
                               RdsDefault.OptionNames[pname])

    
def _remove_all_rds_options(option_settings):            
    for option in option_settings:
        if option.namespace ==  RdsDefault.Namespace:
            option_settings.remove(option)


def _trim_rds_options(option_settings, option_to_remove):
    for option in option_settings:
        if option.namespace ==  RdsDefault.Namespace:
            if option.value is None or len(option.value) == 0:
                _remove_option_setting(option_settings, 
                                       option_to_remove, 
                                       option.namespace, 
                                       option.option_name)


def _update_option_setting(option_settings, namespace, option_name, value):
    for option in option_settings:
        if option.namespace ==  namespace and option.option_name == option_name:
            option.value = value    
            return
    else:
        option_settings.append(ConfigurationOptionSetting(namespace, option_name, value))
        
        
def _remove_option_setting(option_settings, option_to_remove, namespace, option_name):
    for option in option_settings:
        if option.namespace ==  namespace and option.option_name == option_name:
            option_settings.remove(option)
            option_to_remove.add(ConfigurationOptionSetting(namespace, option_name))                
                


