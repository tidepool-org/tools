#! /usr/bin/env node

/*
 * tidepool-pwreset
 * https://github.com/tidepool-org/tools
 * This is a command-line tool intended to run behind the firewall and allow manipulation of the groups associated
 * with a given user.
 *
 * == BSD2 LICENSE ==
 * Copyright (c) 2014, Tidepool Project
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the associated License, which is identical to the BSD 2-Clause
 * License as published by the Open Source Initiative at opensource.org.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the License for more details.
 *
 * You should have received a copy of the License along with this program; if
 * not, you can obtain one from Tidepool Project at tidepool.org.
 * == BSD2 LICENSE ==
 */

'use strict';
var url = require('url');
var util = require('util');
var _ = require('lodash');
var request = require('request');
var async = require('async');
var Cmdline = require('commandline-parser').Parser;
var prompt = require('prompt');
var config = null;
var hakkenClient = null;
  

var username = null;
var password = null;
var deploy = null;  // basename of the configuration file within the config folder


function parseJSON(res, body) {
  return JSON.parse(body);
}

function requestTo(hostGetter, path) {
  var options = {
    method: 'GET',
    headers: {},
    rejectUnauthorized: false
  };

  var statusHandlers = {};

  return {
    withMethod: function(method){
      options.method = method;
      return this;
    },
    withHeader: function(header, value) {
      options.headers[header] = value;
      return this;
    },
    withToken: function(token) {
      return this.withHeader('x-tidepool-session-token', token);
    },
    withBody: function(body) {
      options.body = body;
      return this;
    },
    withJSON: function(json) {
      options.json = json;
      return this;
    },

    /**
     * Registers a function to handle a specific response status code.
     *
     * The return value of the function will be passed to the callback provided on the go() method
     *
     * @param status either a numeric status code or an array of numeric status codes.
     * @param fn A function(response, body){} to use to extract the value from the response
     * @returns {exports}
     */
    whenStatus: function(status, fn) {
      if (Array.isArray(status)) {
        for (var i = 0; i < status.length; ++i) {
          this.whenStatus(status[i], fn);
        }
        return this;
      }

      statusHandlers[status] = fn;
      return this;
    },

    /**
     * Issues the request and calls the given callback.
     * @param cb An idiomatic function(error, result){} callback
     * @returns {*}
     */
    go: function(cb) {
      var hostSpecs = hostGetter.get();
      if (hostSpecs.length < 1) {
        return cb({ statusCode: 503, message: "No hosts found" }, null);
      }
      options.url =

      request(
        util.format('%s%s%s', url.format(hostSpecs[0]), '/', path),
        options,
        function (err, res, body) {
          if (err != null) {
            return cb(err);
          } else if (statusHandlers[res.statusCode] != null) {
            return cb(null, statusHandlers[res.statusCode](res, body));
          } else {
            return cb({ statusCode: res.statusCode, message: util.inspect(body) });
          }
        }
      );
    }
  };
}


function setupCommandline() {
  var parser = new Cmdline({
    name: 'tidepool-pwreset',
    desc: 'A server-side tool for forcing a Tidepool user password to a given value.',
    extra: ['Typical usage:\n',
      'To list the account info:',
      '  tidepool-pwreset --user=doctor@foo.com',
      'To force the password to a known value:',
      '  tidepool-pwreset --user=doctor@foo.com --pw=newpw',
      'To force the password to a value set by a prompt at the command line:',
      '  tidepool-pwreset --user=doctor@foo.com --input',
      '',
      'You can use either an email address or a userid to identify a user.',
      'Note that if you use --pw, the new password will be saved in the history',
      'of your bash shell. This is almost always a bad idea.'].join('\n')
  });

  parser.addArgument('user' ,{
      flags : ['u','user'], 
      desc : "set username or userid of the user whose password is to be set", 
      optional : false,
      action : function(value) {
        username = value;
      }
  });

  parser.addArgument('password' ,{
      flags : ['p','password'], 
      desc : "set the value of password to set (if omitted, user information is printed so you can verify the user first)", 
      optional : true,
      action : function(value) {
        password = value;
      }
  });

  parser.addArgument('input' ,{
      flags : ['i','input'], 
      desc : "set the value of password to the result of a prompt", 
      optional : true,
  });

  parser.addArgument('config' ,{
      flags : ['c','config'], 
      desc : "set config name to use (default is 'config')", 
      optional : true,
      action : function(value) {
        deploy = value;
      }
  });

  parser.addArgument('status', {
      flags : ['s','status'], 
      desc : "check and print status of the servers", 
      optional : true
  });

  return parser;
}

function setup() {
  var parser = setupCommandline();
  parser.exec();

  if (parser.get('help')) {
    process.exit(0);
  }

  if (!username) {
    console.log('user must be specified!');
    parser.printHelp();
    process.exit(1);
  }

  config = require('../env')(deploy);
  // suppress hakken's rather verbose logging
  function nil() {}
  var log = {info:nil, debug:nil, warn:nil, error:nil};
  hakkenClient = require('hakken')(config.discovery, log).client();

  return {
    username: username,
    password: password,
    flags: {status: parser.get('status'), input: parser.get('input')}
  };
}

function getApis(gotApisCB) {
  var apis = {};
  async.waterfall([
    function startHakken(callback) {
      hakkenClient.start(function (err) {
        callback(err);
      });
    },
    function setupUserApi(callback) {
      var userApiWatch = hakkenClient.watchFromConfig(config.userApi.serviceSpec);
      userApiWatch.start(function (err) {
        apis.userHost = userApiWatch;
        if (err) {
          console.log('setupUserApi');
        }
        callback(err);
      });
    },
    ],
    function finishDiscovery(err) {
      if (err) {
        console.log('Failed to complete discovery properly');
        console.log(err);
        process.exit(1);
      }

      apis.user = require('user-api-client').client(config.userApi, apis.userHost);
      if (!apis.user.getUserInfo) {
        console.log(apis.user);
        console.log('The userApiClient is missing a key component, which is probably because SERVER_SECRET is wrong.');
        process.exit(1);
      }

      gotApisCB(apis);
    }
  );

}

function main() {
  var parms = setup();

  // get our APIs from hakken -- user, seagull, armada
  getApis(function gotApisCB(apis) {

    async.waterfall([
      function getPassword(callback) {
        if (parms.flags.input) {
          prompt.start();
          prompt.get(['password'], function(err, result) {
            parms.password = result.password;
            callback(null);
          });
        } else {
          callback(null);
        }
      },
      apis.user.withServerToken,  // calls callback with err, token
      function getUserStatus(token, callback) {
        if (parms.flags.status) {
          console.log('User status:');
          requestTo(apis.userHost, '/status')
            .withToken(token)
            .whenStatus(200, function(err, body) { return body; })
            .go(function(err, status) {
              if (err) {
                console.log(err);
                process.exit(1);
              } else {
                // if we didn't have an error, or the error statusCode wasn't 404, just pass it on
                console.log(status);
                callback(null, token);
              }
            });
        } else {
          callback(null, token);
        }
      },
      function getUserIDfromUserAPI(token, callback) {
        apis.user.getUserInfo(parms.username, function(err, userinfo) {
          if (userinfo) {
            callback(err, token, userinfo);
          } else {
            console.log('Unable to find user information for %s', parms.username);
            process.exit(1);
          }
        });
      },
      function updatePassword(token, userinfo, callback) {
        apis.user.updateUser(userinfo.userid, {password: parms.password}, function(err, newuserinfo) {
            callback(err, token, newuserinfo);
        });
      }
    ], 
    function(err, token, userinfo) {
      if (err) {
        console.log(err);
        console.log('Finished with errors.');
        process.exit(1);
      } else {
        console.log('Successfully set password for %s (%s).', userinfo.username, userinfo.userid);
      }
    });
  });
}

main();
