#!/bin/bash -eux
#
# This code is meant to be executed within a TravisCI build. 

check_go_version() {
    if [ "${TRAVIS_GO_VERSION}" != "${ARTIFACT_GO_VERSION}" ]; then
        echo "Travis GO version does not match Artifact Go Version"
        exit 1
    fi
}

build_go_artifact() {
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
}

    if [ "${TRAVIS_NODE_VERSION}" != "${ARTIFACT_NODE_VERSION}" ]; then
        echo "Travis Node version does not match Artifact Node version"
        exit 1
    fi
}

build_node_artifact() {
    if [ -n "${TRAVIS_TAG:-}" ]; then
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
    fi
}

publish_to_dockerhub() {
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
}

# Allow encoding of behavior in file name for backward compatibility.
me=`basename "$0"`
case $me in
	artifact_go.sh)
		proc=go
		;;
	artifact_node.sh)
		proc=node
		;;
	*)
		proc=$1
		;;
esac

case $proc in 
	go)
		echo "Handling go artifact"
		check_go_version
		build_go_artifact
		publish_to_dockerhub
		;;
	node)
		echo "Handling node artifact"
		check_node_version
		build_node_artifact
		publish_to_dockerhub
		;;
	*)
		echo "Just publishing to Docker Hub"
		publish_to_dockerhub
		;;
esac
