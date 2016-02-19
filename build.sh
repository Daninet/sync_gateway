#!/bin/sh -e

# This script builds sync gateway using pinned dependencies.

## This script is not intended to be run "in place" from a git clone.
## The next check tries to ensure that's the case
if [ -f "main.go" ]; then
    echo "It appears you are trying to run this the wrong way.  See README"
    exit 1
fi 

## Make sure the repo tool is installed, otherwise throw an error
which repo
if (( $? != 0 )); then
    echo "You must install the repo tool first.  Try running: "
    echo "sudo curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/bin/repo"
    exit 1
fi

## If we don't already have a .repo directory, run "repo init"
REPO_DIR=.repo
if [ ! -d "$REPO_DIR" ]; then
    echo "No .repo directory found, running 'repo init'"
    repo init -u "https://github.com/couchbase/sync_gateway.git" -m manifest/default.xml
fi

## Repo Sync
repo sync

## Update the version
SG_DIR=`pwd`/godeps/src/github.com/couchbase/sync_gateway
CURRENT_DIR=`pwd`
BUILD_INFO="./rest/git_info.go"
cd $SG_DIR

#tell git to ignore any local changes to git_info.go, we don't want to commit them to the repo
git update-index --assume-unchanged ${BUILD_INFO}

# Escape forward slash's so sed command does not get confused
# We use thses in feature branches e.g. feature/issue_nnn
GIT_BRANCH=`git status -b -s | sed q | sed 's/## //' | sed 's/\.\.\..*$//' | sed 's/\\//\\\\\//g' | sed 's/[[:space:]]//g'`
GIT_COMMIT=`git rev-parse HEAD`
GIT_DIRTY=$(test -n "`git status --porcelain`" && echo "+CHANGES" || true)

sed -i.bak -e 's/GitCommit.*=.*/GitCommit = "'$GIT_COMMIT'"/' $BUILD_INFO
sed -i.bak -e 's/GitBranch.*=.*/GitBranch = "'$GIT_BRANCH'"/' $BUILD_INFO
sed -i.bak -e 's/GitDirty.*=.*/GitDirty = "'$GIT_DIRTY'"/' $BUILD_INFO

# Go back to previous dir
cd $CURRENT_DIR

## Go Install
GOPATH=`pwd`/godeps go install "$@" github.com/couchbase/sync_gateway/...

echo "Success! Output is godeps/bin/sync_gateway and godeps/bin/sg_accel"
