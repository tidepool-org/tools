FROM anderspitman/tidepool-node:latest
MAINTAINER Anders Pitman <tapitman11@gmail.com>

COPY gatekeeper.tar.gz gatekeeper.tar.gz
COPY launch_container launch_container

ENV PORT=9123
ENV SERVICE_NAME=gatekeeper-local
ENV GATEKEEPER_SECRET="This secret is used to encrypt the groupId stored in the DB for gatekeeper"
ENV MONGO_CONNECTION_STRING "mongodb://tidepool-mongo/gate"

ENTRYPOINT ["sh", "launch_container"]
