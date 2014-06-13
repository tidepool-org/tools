/*
 * == BSD2 LICENSE ==
 */

'use strict';

var async = require('async');

var configName = null;

var parser = new Cmdline(
  {
    name: 'zuul',
    desc: 'A tool for adding and removing people to Tidepool groups directly using the API.',
    extra: [
      'usage:',
      '  zuul <group_id> <action> [arg, ...]',
      'Typical usage:\n',
      'To list people in a group:',
      '  zuul doctor@foo.com show',
      'To add people to a group:',
      '  zuul doctor@bar.com add patient@foo.com',
      'To remove people from a group:',
      '  zuul dontcare@bar.com remove 92c4ebff85',
      '',
      'You can use either an email address or a userid to identify both a group and a user.'
    ].join('\n')
  }
);

parser.addArgument('vebose' ,{
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

var args = parser.getArguments();

if (args.length < 2) {
  parser.printHelp();
}

var handler, userApi, gatekeeper;

function determineHandler() {
  switch(args[1]) {
    case 'show':
      return function(groupId, cb) {
        gatekeeper.usersInGroup(groupId, function(err, users){
          if (err != null) {
            return cb(err);
          }

          Object.keys(users).forEach(function(user){
            console.log('User:\n%s\nPermissions:\n%s', user, users[user]);
          });
        })
      };
      break;
    case 'add':
      return function(groupId, cb) {

      };
      break;
    case 'remove':
      return function(groupId, cb) {

      };
      break;
    default:
      console.log('Unknown verb[%s]', args[1]);
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
        userApi = require('user-api-client')(config.userApi, userApiWatch);
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

    handler(userInfo.userId);
  });
});

