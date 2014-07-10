# tidepool-groupedit

Cmd-line way to set up groups for a user

## Getting Started
Install the module with: `npm install`

## Documentation
    A tool for manipulating Tidepool groups directly using gatekeeper.

    -h, --help    help
    -v, --verbose verbose logging
    -c, --config  set config name to use (default is 'config')

    zuul <group_id> <action> [arg, ...]

    Typical usage:

        To list people in a group:
            `zuul doctor@foo.com show`
        To add people to a group:
            `zuul doctor@bar.com add patient@foo.com`
        To remove people from a group:
            `zuul dontcare@bear.com remove 12f4ebff81`

        You can use either an email address or a userid to identify both a group and a user.

## Release History

* 0.6.0 -- 10 Jul 2014 -- update to use gatekeeper, by Eric Tschetter
* 0.5.0 -- 30 Mar 2014 -- initial version, by Kent Quirk

## License
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


