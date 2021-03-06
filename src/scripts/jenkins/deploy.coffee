# Description:
#   Command to trigger a CI or CD Pipeline via Jenkins
#
# Commands:
#   hubot (ci|cd) <pipeline-name> on <environment> [ with branch=<branch> ...]
#     Deploy or test the application on a certain environment, specified in then
# configuration file.
#   hubot (ci|cd) help
#     Display the entire help section
#   hubot (ci|cd) view rules
#     Display content of the config file

HELP_MESSAGE = """
 Deploy or test the application on a certain environment, specified in then
 configuration file.
 Specify a list of options separated by space, starting from `with` which will
  be sent as build parameters, where the key is the parameter name accepted by
 the job configuration and the key is the value, hence `with branch=staging`
 will set the parameter `branch` as being `staging`.
 """

cson = require('cson')
utils = require('../../utils')

# Load a json file which describes the correlation between command's keywords
# and Jenkins job configuration
jenkinsToken = process.env.HUBOT_DEPLOY_TOKEN
jenkinsData =  cson.parseJSONFile("#{process.env.HUBOT_DEPLOY_DATA_FILE_PATH}")

module.exports = (robot) ->

  robot.respond /(ci|cd) help$/i, (msg) ->
    msg.send HELP_MESSAGE

  robot.respond /(ci|cd) view rules$/i, (msg) ->
    msg.send "Here is the deploy config: #{cson.stringify(jenkinsData)}."

  robot.respond /(ci|cd) (.*) on (\w+)$/i, (msg) ->
    # Trigger a job only with a given repo and environment
    appRepo = msg.match[2]
    appEnv = msg.match[3]

    try
      jenkinsJob = jenkinsData[appRepo][appEnv]
    catch err
      msg.send "Does your mapping exist? Use (ci|cd) view rules"
      return

    response = utils.notifyJenkins jenkinsToken, jenkinsJob, {}

    if response.getCode in [200, 201]
      msg.send "I notified Jenkins to start deploy of #{appRepo} on #{appEnv}."
    else
      msg.send "Error sending request to Jenkins - check your command"

  robot.respond /(ci|cd) (.*) on (\w+) with ([\w-_=\/\\\# ]+)$/i, (msg) ->
    # Trigger a job for a given repo and environment, specifying a list of params
    # The Jenkins job has to be configured beforehand to be able to receive
    # parameters, named as they keys set in the command.
    appRepo = msg.match[2]
    appEnv = msg.match[3]

    try
      jenkinsJob = jenkinsData[appRepo][appEnv]["jobName"]
    catch err
      msg.send "Does your mapping exist? Use (ci|cd) view rules"
      return

    # Transform build params from `key1=value1 key2=value2...` to dict
    buildParams = utils.jsonBuildParams msg.match[4]

    response = utils.notifyJenkins jenkinsToken, jenkinsJob, buildParams

    if response.getCode in [200, 201]
      msg.send "I notified Jenkins to start deploy of #{appRepo}on #{appEnv} with build params."
    else
      msg.send "Error sending request to Jenkins - check your command"
