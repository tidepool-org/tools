#!/bin/bash -eux

if [ "${TRAVIS_GO_VERSION}" != "${ARTIFACT_GO_VERSION}" ]; then
    echo "Travis GO version does not match Artifact Go Version"
    exit 1
fi

if [ -n "${TRAVIS_TAG:-}" ]; then
    ARTIFACT_DIR='deploy'

    APP="${TRAVIS_REPO_SLUG#*/}"
    APP_DIR="${ARTIFACT_DIR}/${APP}"
    APP_TAG="${APP}-${TRAVIS_TAG}"

    rm -rf "${ARTIFACT_DIR}/" || { echo 'ERROR: Unable to delete artifact directory'; exit 1; }
    mkdir -p "${APP_DIR}/" || { echo 'ERROR: Unable to create app directory'; exit 1; }

    ./build.sh || { echo 'ERROR: Unable to build project'; exit 1; }

    mv dist "${APP_DIR}/${APP_TAG}" || { echo 'ERROR: Unable to move app artifact directory'; exit 1; }

    tar -c -z -f "${APP_DIR}/${APP_TAG}.tar.gz" -C "${APP_DIR}" "${APP_TAG}" || { echo 'ERROR: Unable to create artifact'; exit 1; }
fi

if [ -n "${DOCKER_USERNAME:-}" -a -n "${DOCKER_PASSWORD:-}"  ]; then
    DOCKER_REPO="tidepool/${TRAVIS_REPO_SLUG#*/}"
    echo "${DOCKER_PASSWORD}" | docker login --username "${DOCKER_USERNAME}" --password-stdin
    docker build --tag ${DOCKER_REPO} .
    
    if [ "${TRAVIS_BRANCH:-}" == "master" -a "${TRAVIS_PULL_REQUEST_BRANCH:-}" == "" ]; then
        docker push ${DOCKER_REPO}
    fi
    if [ -n "${TRAVIS_TAG:-}" ]; then
        docker tag ${DOCKER_REPO} ${DOCKER_REPO}:${TRAVIS_TAG}
        docker push ${DOCKER_REPO}:${TRAVIS_TAG}
    fi
    if [ -n "${TRAVIS_BRANCH:-}" -a -n "${TRAVIS_COMMIT:-}" ]; then
        docker tag ${DOCKER_REPO} ${DOCKER_REPO}:${TRAVIS_BRANCH}-${TRAVIS_COMMIT}
        docker push ${DOCKER_REPO}:${TRAVIS_BRANCH}-${TRAVIS_COMMIT}
    fi
else
    echo "Missing DOCKER_USERNAME or DOCKER_PASSWORD."
fi
