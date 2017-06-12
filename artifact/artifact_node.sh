#!/bin/sh -e

if [ -z "${TRAVIS_TAG}" ]; then
    exit 0
fi

set -u

if [ "${TRAVIS_NODE_VERSION}" != "${ARTIFACT_NODE_VERSION}" ]; then
    exit 0
fi

ARTIFACT_DIR='deploy'

APP="${TRAVIS_REPO_SLUG#*/}"
APP_DIR="${ARTIFACT_DIR}/${APP}"
APP_TAG="${APP}-${TRAVIS_TAG}"

TMP_DIR="/tmp/${TRAVIS_REPO_SLUG}"

if [ -f '.artifactignore' ]; then
    RSYNC_OPTIONS='--exclude-from=.artifactignore'
else
    RSYNC_OPTIONS=''
fi

rm -rf "${ARTIFACT_DIR}/" "${TMP_DIR}/" || { echo 'ERROR: Unable to delete artifact and tmp directories'; exit 1; }
mkdir -p "${APP_DIR}/" "${TMP_DIR}/" || { echo 'ERROR: Unable to create app and tmp directories'; exit 1; }

./build.sh || { echo 'ERROR: Unable to build project'; exit 1; }

rsync -a ${RSYNC_OPTIONS} . "${TMP_DIR}/${APP_TAG}/" || { echo 'ERROR: Unable to copy files'; exit 1; }

tar -c -z -f "${APP_DIR}/${APP_TAG}.tar.gz" -C "${TMP_DIR}" "${APP_TAG}" || { echo 'ERROR: Unable to create artifact'; exit 1; }

rm -rf "${TMP_DIR}/"
