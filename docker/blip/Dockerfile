FROM anderspitman/tidepool-node:latest
MAINTAINER Anders Pitman <tapitman11@gmail.com>

COPY blip.tar.gz blip.tar.gz
COPY launch_container launch_container

ENV PORT 3000
ENV MOCK false
ENV API_HOST "http://tidepool-styx:8009"
ENV UPLOAD_API "http://tidepool.org/uploader"
ENV SERVICE_NAME blip-local

ENV MONGO_CONNECTION_STRING "mongodb://tidepool-mongo/streams"

ENTRYPOINT ["sh", "launch_container"]
