var fs = require('fs');
var url = require('url');

var _ = require('lodash');
var cli = require('cli');
var httpClient = require('amoeba').httpClient({ secureSsl: true });
var userApi = require('user-api-client');

cli.parse(
  {
    username: ['u', 'username', 'string'],
    password: ['p', 'password', 'string'],
    apiHost: [null, 'tidepool api host', 'url', 'http://localhost:8009'],
    uploadHost: [null, 'tidepool upload host', 'url', 'http://localhost:9122'],
    data: ['d', 'path to data file to upload', 'path', __dirname + '/data/test.json']
  }
);

cli.main(function (args, options) {
  options.password = String(options.password);
  options.apiHost = url.parse(options.apiHost);
  options.uploadHost = url.parse(options.uploadHost);

  var userApiClient = userApi.client({pathPrefix: 'auth' }, { get: function () {
    return [options.apiHost]
  }});

  userApiClient.login(options.username, options.password, function (err, token) {
    if (err != null) {
      console.log(err.stack);
      return;
    }

    var dataToPost = JSON.parse(fs.readFileSync(options.data));

    httpClient.requestTo(_.assign({}, options.uploadHost, { pathname: '/data' }))
      .withMethod('POST')
      .withToken(token)
      .withJson(dataToPost)
      .whenStatusPassBody(200)
      .go(function (err, body) {
            if (err != null) {
              if (err.statusCode == null) {
                console.log(err.stack);
              } else {
                console.log(err.message);
              }
            } else {
              console.log('Data uploaded successfully');
              console.log(body);
            }
          });
  });
});