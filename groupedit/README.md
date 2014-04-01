# tidepool-groupedit

Cmd-line way to set up groups for a user

## Getting Started
Install the module with: `npm install tidepool-groupedit`

## Documentation
    A server-side tool for adding and removing people to Tidepool groups.

    -h, --help  help
    -u, --user  set username containing the group to modify
    -g, --group set group name to modify (default is team)
    -a, --add   add members to the group
    -d, --del   delete members from the group
    -s, --status check and print status of the servers
    
    Typical usage:

        To list people in a group:
          tidepool-groupedit --group=patients --user=doctor@foo.com
        To add people to a group:
          tidepool-groupedit --add --group=invited --user=patient@foo.com doctor@bar.com
        To list people in a group:
          tidepool-groupedit --del --group=careteam --user=patient@foo.com dontcare@bar.com badguy@unsafe.com

        You can use either an email address or the userid to identify a user.

## Release History

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


