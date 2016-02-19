#!/bin/sh -e

set -x

# This script builds sync gateway using pinned dependencies.

# Function which rewrites the manifest according to the commit passed in arguments.
# This is needed by the CI system in order to test feature branches.
#
# Steps
#   - Fetches manifest with given commit
#   - Updates sync gateway pinned commit to match the given commit (of feature branch)
#   - Overwrites .repo/manifest.xml with this new manifest
#
# It should be run *before* 'repo sync'
rewriteManifest () {
    BRANCH="$1"
    COMMIT="$2"
    echo "Manifest before rewrite"
    cat .repo/manifest.xml
    curl "https://raw.githubusercontent.com/tleyden/sync_gateway/$2/rewrite-manifest.sh" > rewrite-manifest.sh
    chmod +x rewrite-manifest.sh
    ./rewrite-manifest.sh --manifest-url "https://raw.githubusercontent.com/tleyden/sync_gateway/$2/manifest/default.xml" --project-name "sync_gateway" --set-revision "$2" > .repo/manifest.xml
    echo "Manifest after rewrite"
    cat .repo/manifest.xml    
}

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

## If two command line args were passed in (branch and commit), then rewrite manifest.xml
if [ "$#" -eq 2 ]; then
    rewriteManifest
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
GOPATH=`pwd`/godeps go install github.com/couchbase/sync_gateway/...

echo "Success! Output is godeps/bin/sync_gateway and godeps/bin/sg_accel "

