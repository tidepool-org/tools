FROM anderspitman/tidepool-node:latest
MAINTAINER Anders Pitman <tapitman11@gmail.com>

# TODO: Solve for real
# For some reason npm install fails inside docker containers due to execSync,
# which is a dependency of grunt-shell-spawn. The purpose of this docker
# container is to run a simple seagull instance, so grunt-shell-spawn isn't
# necessary. This sed line simply removes the npm dependency from package.json.
#RUN sed -i '/grunt-shell-spawn/d' package.json

COPY launch_container launch_container
COPY seagull.tar.gz seagull.tar.gz

ENV PORT=9120
ENV SERVICE_NAME=seagull-local
ENV SALT_DEPLOY=KEWRWBe5yyMnW4SxosfZ2EkbZHkyqJ5f
ENV MONGO_CONNECTION_STRING "mongodb://tidepool-mongo/user"

ENTRYPOINT ["sh", "launch_container"]
