#! /usr/bin/env node

/*
 * tidepool-groupedit
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
var config = require('../env');
var hakkenClient = require('hakken')(config.discovery).client();
  

var username = null;
var groupname = 'team';


function randomIdentifier(n) {
  var validChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  var id = '';
  for (var i = 0; i <10; i++) {
    id += validChars[Math.floor(Math.random() * validChars.length)];
  };
  return id;
}

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
  }
}


function setupCommandline() {
  var parser = new Cmdline({
    name: 'tidepool-groupedit',
    desc: 'A server-side tool for adding and removing people to Tidepool groups.',
    extra: ['Typical usage:\n',
      'To list people in a group:',
      '  tidepool-groupedit --group=patients --user=doctor@foo.com',
      'To add people to a group:',
      '  tidepool-groupedit --add --group=invited --user=patient@foo.com doctor@bar.com',
      'To remove people from a group:',
      '  tidepool-groupedit --del --group=careteam --user=patient@foo.com dontcare@bar.com 92c4ebff85',
      '',
      'You can use either an email address or a userid to identify a user.'].join('\n')
  });

  parser.addArgument('user' ,{
      flags : ['u','user'], 
      desc : "set username containing the group to modify", 
      optional : false,
      action : function(value, parser) {
        username = value;
      }
  });

  parser.addArgument('group' ,{
      flags : ['g','group'], 
      desc : "set group name to modify (default is team)", 
      optional : true,
      action : function(value, parser) {
        groupname = value;
      }
  });

  parser.addArgument('add', {
      flags : ['a','add'], 
      desc : "add members to the group", 
      optional : true
  });

  parser.addArgument('del', {
      flags : ['d','del'], 
      desc : "delete members from the group", 
      optional : true
  });

  parser.addArgument('status', {
      flags : ['s','status'], 
      desc : "check and print status of the servers", 
      optional : true
  });

  return parser;
};

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
  var args = parser.getArguments();
  if (args.length < 1 && (parser.get('add') || parser.get('del'))) {
    console.log('You must specify at least one group member to add or remove from the group.');
    parser.printHelp();
    process.exit(1);
  }
  return {
    username: username,
    groupname: groupname,
    members: args,
    flags: {add: parser.get('add'), del: parser.get('del'), status: parser.get('status')}
  }
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
    function setupSeagullApi(callback) {
      var seagullApiWatch = hakkenClient.watchFromConfig(config.seagullApi.serviceSpec);
      seagullApiWatch.start(function (err) {
        apis.seagullHost = seagullApiWatch;
        if (err) {
          console.log('setupSeagullApi');
        }
        callback(err);
      });
    },
    function setupArmadaApi(callback) {
      var armadaApiWatch = hakkenClient.watchFromConfig(config.armadaApi.serviceSpec);
      armadaApiWatch.start(function (err) {
        apis.armadaHost = armadaApiWatch;
        if (err) {
          console.log('setupArmadaApi');
        }
        callback(err);
      });
    }
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
      };

      gotApisCB(apis);
    }
  );

}



function main() {
  var parms = setup();

  // get our APIs from hakken -- user, seagull, armada
  getApis(function gotApisCB(apis) {

    async.waterfall([
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
                callback(null, status);
              }
            });
        }
      },
      function getSeagullStatus(token, callback) {
        if (parms.flags.status) {
          console.log('Seagull status:');
          requestTo(apis.seagullHost, '/status')
            .withToken(token)
            .whenStatus(200, function(err, body) { return body; })
            .go(function(err, status) {
              if (err) {
                console.log(err);
                process.exit(1);
              } else {
                // if we didn't have an error, or the error statusCode wasn't 404, just pass it on
                console.log(status);
                callback(null, status);
              }
            });
        }
      },
      function getArmadaStatus(token, callback) {
        if (parms.flags.status) {
          console.log('Armada status:');
          requestTo(apis.armadaHost, '/status')
            .withToken(token)
            .whenStatus(200, function(err, body) { return body; })
            .go(function(err, status) {
              if (err) {
                console.log(err);
                process.exit(1);
              } else {
                // if we didn't have an error, or the error statusCode wasn't 404, just pass it on
                console.log(status);
                callback(null, status);
              }
            });
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
      function getAllUserIDs(token, userinfo, callback) {
        var getOneUserID = function (user, gotUserCB) {
          apis.user.getUserInfo(user, function(err, userinfo) {
            if (err || userinfo == null) {
              gotUserCB(null, null);
            } else {
              gotUserCB(null, userinfo.userid);
            }
          });
        }
        async.map(parms.members, getOneUserID, function(err, results) {
          parms.newmembers = _.compact(results);
          callback(null, token, userinfo);
        });
      },
      function getGroupsfromSeagull(token, userinfo, callback) {
        requestTo(apis.seagullHost, userinfo.userid + '/groups')
          .withToken(token)
          .whenStatus(200, parseJSON)
          .go(function(err, groupinfo) {
            if (err && err.statusCode === 404) {
              console.log('There was no groups object for that user; aborting.');
              process.exit(1);
            } else {
              // if we didn't have an error, or the error statusCode wasn't 404, just pass it on
              callback(err, token, userinfo, groupinfo);
            }
          });
      },
      function maybeCreateGroupInArmada(token, userinfo, groupinfo, callback) {
        if (!groupinfo[parms.groupname]) {
          if (parms.flags.del) {
            console.log('Cannot delete someone from a group that does not exist.');
            process.exit(1);
          }
          requestTo(apis.armadaHost, '')    // create group has no command
            .withMethod('POST')
            .withToken(token)
            .withJSON({group: {members: parms.newmembers}})
            .whenStatus(201, function(res, body) { return body; })
            .go(function(err, newgroup) {
              if (err) {
                console.log(err);
                console.log('Failed to create a new group; aborting.');
                process.exit(1);
              } else {
                // if we didn't have an error, just pass it on
                groupinfo[parms.groupname] = newgroup.id;
                console.log('Created a new group with id ', newgroup.id);
                callback(err, token, userinfo, groupinfo);
              }
            });
        } else {
          callback(null, token, userinfo, groupinfo);
        }
      },
      function modifyArmadaGroup(token, userinfo, groupinfo, callback) {
        var addOneUserToGroup = function(userid, addedUserCB) {
          requestTo(apis.armadaHost, groupinfo[parms.groupname] + '/user')
            .withMethod('PUT')
            .withToken(token)
            .withJSON({userid: userid})
            .go(function(err, result) {
              if (err) {
                addedUserCB(err, null);
              } else {
                addedUserCB(null, result);
              }
          });
        };
        var removeOneUserFromGroup = function(userid, removedUserCB) {
          requestTo(apis.armadaHost, groupinfo[parms.groupname] + '/user')
            .withMethod('DELETE')
            .withToken(token)
            .withJSON({userid: userid})
            .go(function(err, result) {
              if (err) {
                removedUserCB(err, null);
              } else {
                removedUserCB(null, result);
              }
          });
        };
        if (parms.flags.add) {
          async.map(parms.newmembers, addOneUserToGroup, function(err, results) {
            callback(null, token, userinfo, groupinfo);
          });
        } else if (parms.flags.del) {
          async.map(parms.newmembers, removeOneUserFromGroup, function(err, results) {
            callback(null, token, userinfo, groupinfo);
          });
        } else {       
          callback(null, token, userinfo, groupinfo);
        };
      },
      function saveGroupsToSeagull(token, userinfo, groupinfo, callback) {
        requestTo(apis.seagullHost, userinfo.userid + '/groups')
          .withMethod('PUT')
          .withToken(token)
          .withJSON(groupinfo)
          .whenStatus(200, function(res, body) { return body; })
          .go(function(err, groupinfo) {
            if (err) {
              console.log('Tried to update groups but failed; aborting.');
              process.exit(1);
            } else {
              // if we didn't have an error, or the error statusCode wasn't 404, just pass it on
              callback(err, token, userinfo, groupinfo);
            }
          });
      },
      function getGroupMembersFromArmada(token, userinfo, groupinfo, callback) {
        requestTo(apis.armadaHost, groupinfo[parms.groupname] + '/members')    // create group has no command
          .withMethod('GET')
          .withToken(token)
          .whenStatus(200, function(res, body) { return body; })
          .go(function(err, newgroup) {
            if (err) {
              console.log(err);
              console.log('Failed to retrieve the group we just created; aborting.');
              process.exit(1);
            } else {
              console.log('Group membership now includes these user IDs:', newgroup);
              callback(err, token, userinfo, groupinfo);
            }
          });
      }
    ], 
    function(err, token, userinfo, groupinfo) {
      if (err) {
        console.log(err);
        console.log('Finished with errors.');
        process.exit(1);
      } else {
        console.log('Finished.');
      }
    });
  });
}

main();
