#!/bin/bash
# Deploy to test site (jon-test.ludl.am)

set -ex

# Ensure opam environment is set up
eval $(opam env --switch=5.2.0)

# Build the site
./build.sh

# Incremental sync to test server
rsync -avz --delete -e "ssh -o IgnoreUnknown=UseKeychain" _tmp/html/ jon@jon.recoil.org:/var/www/jon-test.ludl.am/

echo "Deployed to test site: https://jon-test.ludl.am"
