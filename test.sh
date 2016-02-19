#!/bin/sh -e

# Make sure that build.sh has been run first
SG_DIR=`pwd`/godeps/src/github.com/couchbase/sync_gateway
if [ ! -d "$SG_DIR" ]; then
    echo "You must run build.sh before running the tests"
    exit 1
fi

# Run tests
GOPATH=`pwd`/godeps go test "$@" github.com/couchbase/sync_gateway/...
