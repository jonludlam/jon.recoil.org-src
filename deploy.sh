#!/bin/bash
# Deploy to production site (jon.recoil.org)

set -ex

# Ensure opam environment is set up
eval $(opam env --switch=5.2.0)

# Build the site
./build.sh

# Create tarball
(cd _tmp/html && tar jcf /tmp/site.tar.bz2 .)

# Deploy to production server
scp /tmp/site.tar.bz2 jon@jon.recoil.org:
ssh jon@jon.recoil.org 'cd /var/www/jon.recoil.org && tar jxvf ~/site.tar.bz2'

echo "Deployed to production: https://jon.recoil.org"
