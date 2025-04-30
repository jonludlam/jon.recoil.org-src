#!/bin/bash

set -ex

docker build . -t foo
img=$(docker create foo)
docker cp $img:/build/site.tar.bz2 /tmp/
dir=`mktemp -d -t site`
cd $dir
tar jxvf /tmp/site.tar.bz2
echo results in $dir



