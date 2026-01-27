#!/bin/bash
# Deploy to test site (jon-test.ludl.am)

set -ex

# Ensure opam environment is set up
eval $(opam env --switch=5.2.0)

# Build the site
./build.sh

# Create tarball
(cd _tmp/html && tar jcf /tmp/site.tar.bz2 .)

# Deploy to test server
scp /tmp/site.tar.bz2 jon@jon.recoil.org:
ssh jon@jon.recoil.org 'cd /var/www/jon-test.ludl.am && tar jxvf ~/site.tar.bz2'

echo "Deployed to test site: https://jon-test.ludl.am"
