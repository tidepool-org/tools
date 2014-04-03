/*
== BSD2 LICENSE ==
Copyright (c) 2014, Tidepool Project

This program is free software; you can redistribute it and/or modify it under
the terms of the associated License, which is identical to the BSD 2-Clause
License as published by the Open Source Initiative at opensource.org.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the License for more details.

You should have received a copy of the License along with this program; if
not, you can obtain one from Tidepool Project at tidepool.org.
== BSD2 LICENSE ==
*/
'use strict';

var amoeba = require('amoeba');
var config = amoeba.config;

var fs = require('fs');
function maybeReadJSONFile(filename, fallback)
{
  if (fs.existsSync(filename)) {
    var json = fs.readFileSync(filename);//.toString();
    var data = JSON.parse(json);
    return data;
  }
  return fallback;
}

var configfile = null; 

function getConfig(name, fallback) {
  if (configfile[name]) {
    return configfile[name];
  } else {
    return config.fromEnvironment(name, fallback)
  }
}

module.exports = (function() {
  return function (deploy) {
    var env = {}; 
    var depl = deploy || 'config';
    var configfilename = 'config/' + depl + '.json';
    configfile = maybeReadJSONFile(configfilename, {});
    // Name of this server to pass to user-api when getting a server token
    var serverName = getConfig('SERVER_NAME', 'groupedit');
    // The secret to use when getting a server token from user-api
    var serverSecret = getConfig('SERVER_SECRET');

    env.userApi = {
      // The config object to discover user-api.  This is just passed through to hakken.watchFromConfig()
      serviceSpec: JSON.parse(getConfig('USER_API_SERVICE')),
      serverName: serverName,
      serverSecret: serverSecret
    };

    env.seagullApi = {
      // The config object to discover user-api.  This is just passed through to hakken.watchFromConfig()
      serviceSpec: JSON.parse(getConfig('SEAGULL_SERVICE')),
      serverName: serverName,
      serverSecret: serverSecret
    };

    env.armadaApi = {
      // The config object to discover user-api.  This is just passed through to hakken.watchFromConfig()
      serviceSpec: JSON.parse(getConfig('ARMADA_SERVICE')),
      serverName: serverName,
      serverSecret: serverSecret
    };

    // The host to contact for discovery
    if (getConfig('DISCOVERY_HOST') != null) {
      env.discovery = {
        host: getConfig('DISCOVERY_HOST')
      };
    }

    return env;
  }
})();
