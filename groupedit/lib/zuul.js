/*
 * == BSD2 LICENSE ==
 */

'use strict';

var async = require('async');

var Cmdline = require('commandline-parser').Parser;

var configName = null;

var parser = new Cmdline(
  {
    name: 'zuul',
    desc: 'A tool for manipulating Tidepool groups directly using the API.',
    extra: [
      '  zuul <group_id> <action> [arg, ...]',
      'Typical usage:\n',
      'To list people in a group:',
      '  zuul doctor@foo.com show',
      'To add people to a group:',
      '  zuul doctor@bar.com add patient@foo.com',
      'To remove people from a group:',
      '  zuul dontcare@bar.com remove 92c4ebff85',
      '',
      'You can use either an email address or a userid to identify both a group and a user.',
      'Valid actions are show, add, remove.'
    ].join('\n')
  }
);

parser.addArgument('verbose' ,{
  flags : ['v','verbose'],
  desc : "verbose logging",
  optional : true
});

parser.addArgument('config' ,{
  flags : ['c','config'],
  desc : "set config name to use (default is 'config')",
  optional : true,
  action : function(value) {
    configName = value;
  }
});

parser.exec();

if (parser.get('help')) {
  return;
}

var args = parser.getArguments();

if (args.length < 2) {
  parser.printHelp();
  return;
}

var handler, userApi, gatekeeper;

function lookupUsernames(userIds, cb) {
  async.map(userIds, userApi.getUserInfo.bind(userApi), function(err, names){
    if (err != null){
      return cb(err);
    }

    var retVal = {};

    for (var i = 0; i < userIds.length; ++i) {
      if (names[i] != null) {
        retVal[userIds[i]] = names[i].username;
      }
    }

    cb(null, retVal);
  });
}

function determineHandler() {
  var newPermissions = {};

  function show(groupId, cb) {
    gatekeeper.usersInGroup(groupId, function(err, users){
      if (err != null) {
        return cb(err);
      }

      lookupUsernames(Object.keys(users), function(err, usernames){
        if (err != null) {
          return cb(err);
        }

        Object.keys(users).forEach(function(user){
          console.log('User: %s\nPermissions: %j\n-----', usernames[user], users[user]);
        });
      });
    });
  }

  var action = args[1];
  switch(action) {
    case 'show':
      return show;
    case 'add':
      newPermissions = {view: {}};
      // fall-through
    case 'remove':
      return function(groupId, cb) {
        if (args.length < 3) {
          console.log('Must specify a 3rd argument with the `%s` action.', action);
          process.exit();
        }

        async.map(
          args.slice(2),
          function(userToAdd, cb) {
            if (userToAdd == null) {
              console.log('Got a null argument on command line at index[%s]!?', i);
              return cb();
            }

            userApi.getUserInfo(userToAdd, function(err, userInfo){
              if (err != null) {
                return cb(err);
              }

              gatekeeper.setPermissions(userInfo.userid, groupId, newPermissions, function(err) {
                if (err != null) {
                  return cb(err);
                }

                cb()
              });
            });
          },
          function(err) {
            if (err != null) {
              return cb(err);
            }
            show(groupId, cb);
          }
        );
      };
    default:
      console.log('Unknown verb[%s]', action);
      parser.printHelp();
      process.exit(1);
  }
}

function init(cb) {
  var config = require('../env.js')(configName);

  // noop logger to suppress hakken's logging
  function nil() {}
  var log = {info:nil, debug:nil, warn:nil, error:nil};
  var hakken = require('hakken')(config.discovery, parser.get('verbose') ? null : log).client();

  hakken.start(function(err){
    if (err != null) {
      return cb(err);
    }

    var userApiWatch = hakken.watchFromConfig(config.userApi.serviceSpec);
    var gatekeeperWatch = hakken.watchFromConfig(config.gatekeeper.serviceSpec);

    async.parallel(
      [userApiWatch.start.bind(userApiWatch), gatekeeperWatch.start.bind(gatekeeperWatch)],
      function(err) {
        if (err != null) {
          return cb(err);
        }

        var httpClient = require('amoeba').httpClient();
        userApi = require('user-api-client').client(config.userApi, userApiWatch);
        gatekeeper = require('tidepool-gatekeeper').client(
          httpClient, userApi.withServerToken.bind(userApi), gatekeeperWatch
        );
        return cb();
      }
    );
  });
}

function noErr(err) {
  if (err != null) {
    console.log(err.stack);
    process.exit(1);
  }
}

handler = determineHandler();
init(function(err){
  noErr(err);

  var groupId = args[0];
  userApi.getUserInfo(groupId, function(err, userInfo) {
    noErr(err);

    handler(userInfo.userid, noErr);
  });
});

