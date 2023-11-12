#!/bin/bash -eux

# This code is meant to be executed within a CI build.

publish_to_dockerhub() {
    if [ -n "${DOCKER_USERNAME:-}" ] && [ -n "${DOCKER_PASSWORD:-}" ]; then

        # Determine CI provider
        if [ -n "${TRAVIS:-}" ]; then
            CI_PROVIDER="travis"
        elif [ -n "${CIRCLECI:-}" ]; then
            CI_PROVIDER="circle"
        else
            echo "No known CI provider detected"
            return 1
        fi

        # Set common variables
        if [ "$CI_PROVIDER" = "travis" ]; then
            REPO_SLUG=$TRAVIS_REPO_SLUG
            COMMIT=$TRAVIS_COMMIT
            TAG=${TRAVIS_TAG:-}
            BRANCH=${TRAVIS_BRANCH:-}
            PR_NUMBER=${TRAVIS_PULL_REQUEST:-}
        elif [ "$CI_PROVIDER" = "circle" ]; then
            REPO_SLUG="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
            COMMIT=$CIRCLE_SHA1
            TAG=${CIRCLE_TAG:-}
            BRANCH=${CIRCLE_BRANCH:-}
            PR_NUMBER=${CIRCLE_PR_NUMBER:-}
        fi

        if [ -z "${PR_NUMBER}" ]; then
            IS_PULL_REQUEST=false
        else
            IS_PULL_REQUEST=true
        fi

        DOCKER_REPO="tidepool/${REPO_SLUG#*/}"

        echo "${DOCKER_PASSWORD}" | docker login --username "${DOCKER_USERNAME}" --password-stdin
        if [ "${REPO_SLUG:-}" == "tidepool-org/blip" ] || [ "${REPO_SLUG:-}" == "tidepool-org/uploader" ]; then
            # Build blip or uploader image
            RX_ENABLED=${RX_ENABLED-false}
            if [[ ",${RX_ENABLED_BRANCHES:-}," = *",${BRANCH},"* ]]; then RX_ENABLED=true; fi
            DOCKER_BUILDKIT=1 docker build --tag "${DOCKER_REPO}" --build-arg ROLLBAR_POST_SERVER_TOKEN="${ROLLBAR_POST_SERVER_TOKEN:-}" --build-arg LAUNCHDARKLY_CLIENT_TOKEN="${LAUNCHDARKLY_CLIENT_TOKEN:-}" --build-arg REACT_APP_GAID="${REACT_APP_GAID:-}" --build-arg RX_ENABLED="${RX_ENABLED:-}" --build-arg TRAVIS_COMMIT="${COMMIT:-}" .
        else
            # Build other images
            docker build --tag "${DOCKER_REPO}" .
        fi

        if [ "${BRANCH:-}" == "master" ] && [ ${IS_PULL_REQUEST} == false ]; then
            # Push master branch image
            docker push "${DOCKER_REPO}"
        fi

        if [ -n "${TAG:-}" ]; then
            # Push git tag image
            docker tag "${DOCKER_REPO}" "${DOCKER_REPO}:${TAG}"
            docker push "${DOCKER_REPO}:${TAG}"
        fi

        if [ -n "${BRANCH}" ] && [ -n "$COMMIT" ]; then
            if [ ${IS_PULL_REQUEST} == true ]; then
                TAG="PR-${PR_NUMBER}"
            else
                TAG=$(echo -n ${BRANCH} | tr / -)
            fi
            # Push commit and timestamp images
            docker tag "${DOCKER_REPO}" "${DOCKER_REPO}:${TAG}-${COMMIT}"
            docker push "${DOCKER_REPO}:${TAG}-${COMMIT}"

            TIMESTAMP=$(date +%s)
            docker tag "${DOCKER_REPO}" "${DOCKER_REPO}:${TAG}-${TIMESTAMP}"
            docker push "${DOCKER_REPO}:${TAG}-${TIMESTAMP}"

            # Push PR latest image
            docker tag "${DOCKER_REPO}" "${DOCKER_REPO}:${TAG}-latest"
            docker push "${DOCKER_REPO}:${TAG}-latest"

        fi

    else
        echo "Missing DOCKER_USERNAME or DOCKER_PASSWORD."
    fi

}

publish_to_dockerhub
