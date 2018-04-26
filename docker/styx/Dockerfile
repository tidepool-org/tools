FROM anderspitman/tidepool-node:latest
MAINTAINER Anders Pitman <tapitman11@gmail.com>

COPY styx_rules.json styx_rules.json
COPY launch_container launch_container
COPY styx.tar.gz styx.tar.gz
COPY sslKey.pem sslKey.pem
COPY sslCert.pem sslCert.pem

ENV HTTP_PORT 8009
ENV DISCOVERY "\
{\
  \"host\": \"localhost:8000\"\
}"
ENV HTTPS_PORT 8010
ENV HTTPS_CONFIG "\
{\
  \"key\": \"../sslKey.pem\",\
  \"cert\": \"../sslCert.pem\"\
}"

RUN sed -i -e 's/localhost:9107/tidepool-shoreline:9107/g' styx_rules.json
RUN sed -i -e 's/localhost:9120/tidepool-seagull:9120/g' styx_rules.json
RUN sed -i -e 's/localhost:9122/tidepool-jellyfish:9122/g' styx_rules.json
RUN sed -i -e 's/localhost:9123/tidepool-gatekeeper:9123/g' styx_rules.json

ENTRYPOINT ["sh", "launch_container"]
