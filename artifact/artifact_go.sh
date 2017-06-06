#!/bin/sh -e

if [ -z "${TRAVIS_TAG}" ]; then
    exit 0
fi

set -u

if [ "${TRAVIS_GO_VERSION}" != "${ARTIFACT_GO_VERSION}" ]; then
    exit 0
fi

ARTIFACT_DIR='deploy'

APP="${TRAVIS_REPO_SLUG#*/}"
APP_DIR="${ARTIFACT_DIR}/${APP}"
APP_TAG="${APP}-${TRAVIS_TAG}"

rm -rf "${ARTIFACT_DIR}/" || { echo 'ERROR: Unable to delete artifact directory'; exit 1; }
mkdir -p "${APP_DIR}/" || { echo 'ERROR: Unable to create app directory'; exit 1; }

./build.sh || { echo 'ERROR: Unable to build project'; exit 1; }

mv dist "${APP_DIR}/${APP_TAG}" || { echo 'ERROR: Unable to move app artifact directory'; exit 1; }

tar -c -z -f "${APP_DIR}/${APP_TAG}.tar.gz" -C "${APP_DIR}" "${APP_TAG}" || { echo 'ERROR: Unable to create artifact'; exit 1; }
