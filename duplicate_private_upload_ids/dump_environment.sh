#!/bin/bash -eu

echo "Environment Variables:"
echo
echo "ENVIRONMENT=${ENVIRONMENT:-}"
echo "SERVER_SECRET=${SERVER_SECRET:-}"
echo "SALT_DEPLOY=${SALT_DEPLOY:-}"
echo "SHORELINE_API=${SHORELINE_API:-}"
echo "SEAGULL_API=${SEAGULL_API:-}"
echo "MONGO_OPTIONS=${MONGO_OPTIONS:-}"
echo
echo "Executables:"
echo
echo "mongo:$(which mongo)"
echo "base64:$(which base64)"
echo "openssl:$(which openssl)"
echo "jq:$(which jq)"
