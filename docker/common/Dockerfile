FROM alpine:3.2
#FROM alpine:edge
MAINTAINER Anders Pitman <tapitman11@gmail.com>

ENV API_SECRET "This is a local API secret for everyone. BsscSHqSHiwrBMJsEGqbvXiuIUPAjQXU"
ENV SERVER_SECRET "This needs to be the same secret everywhere. YaHut75NsK1f9UKUXuWqxNN0RUwHFBCy"
ENV LONGTERM_KEY "abcdefghijklmnopqrstuvwxyz"
ENV DISCOVERY_HOST localhost:8000
ENV PUBLISH_HOST localhost
ENV METRICS_SERVICE "{ \"type\": \"static\", \"hosts\": [{ \"protocol\": \"http\", \"host\": \"tidepool-highwater:9191\" }] }"
ENV USER_API_SERVICE "{ \"type\": \"static\", \"hosts\": [{ \"protocol\": \"http\", \"host\": \"tidepool-shoreline:9107\" }] }"
ENV SEAGULL_SERVICE "{ \"type\": \"static\", \"hosts\": [{ \"protocol\": \"http\", \"host\": \"tidepool-seagull:9120\" }] }"
ENV GATEKEEPER_SERVICE "{ \"type\": \"static\", \"hosts\": [{ \"protocol\": \"http\", \"host\": \"tidepool-gatekeeper:9123\" }] }"
