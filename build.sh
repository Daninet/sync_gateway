#!/bin/sh -e

set -x

# This script builds sync gateway using pinned dependencies.

## This script is not intended to be run "in place" from a git clone.
## The next check tries to ensure that's the case
if [ -f "main.go" ]; then
    echo "This script is meant to run outside the clone directory.  See README"
    exit 1
fi 

## Make sure the repo tool is installed, otherwise throw an error
if ! type "repo" > /dev/null; then
    echo "Did not find repo tool, downloading to current directory"
    curl https://storage.googleapis.com/git-repo-downloads/repo > repo
    chmod +x repo
    export PATH=$PATH:.
fi

## If we don't already have a .repo directory, run "repo init"
REPO_DIR=.repo
if [ ! -d "$REPO_DIR" ]; then
    echo "No .repo directory found, running 'repo init'"
    repo init -u "https://github.com/tleyden/sync_gateway.git" -m manifest/default.xml
fi

# Fetches manifest with given commit
# Updates sync gateway pinned commit to match the feature branch
# Overwrites .repo/manifest.xml with this new manifest
echo "argv1: $1 argv2: $2"
if [ -z "$1" ]; then
    echo "Have argv1"
    if [ "$1" == "master" ]; then
	echo "Manifest before rewrite"
	cat ./repo/manifest.xml
	curl https://raw.githubusercontent.com/tleyden/sync_gateway/master/rewrite-manifest.sh > rewrite-manifest.sh
	chmod +x rewrite-manifest.sh
	./rewrite-manifest.sh --manifest-url "https://raw.githubusercontent.com/tleyden/sync_gateway/$2/manifest/default.xml" --project-name "sync_gateway" --set-revision "$2" > .repo/manifest.xml
	echo "Manifest after rewrite"
	cat ./repo/manifest.xml
    fi
fi

## Repo Sync
repo sync

## Update the version stamp in the code
SG_DIR=`pwd`/godeps/src/github.com/couchbase/sync_gateway
CURRENT_DIR=`pwd`
cd $SG_DIR
./set-version-stamp.sh
cd $CURRENT_DIR

## Go Install
GOPATH=`pwd`/godeps go install "$@" github.com/couchbase/sync_gateway/...

echo "Success! Output is godeps/bin/sync_gateway and godeps/bin/sg_accel "

