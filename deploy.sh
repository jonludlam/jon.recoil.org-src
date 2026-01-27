#!/bin/bash
# Deploy to production site (jon.recoil.org)

set -ex

# Ensure opam environment is set up
eval $(opam env --switch=5.2.0)

# Build the site
./build.sh

# Incremental sync to production server
rsync -avz --delete _tmp/html/ jon@jon.recoil.org:/var/www/jon.recoil.org/

echo "Deployed to production: https://jon.recoil.org"
