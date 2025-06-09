#!/bin/bash

set -ex

docker build . -t foo
img=$(docker create foo)
docker cp $img:/build/site.tar.bz2 .
scp site.tar.bz2 jon@jon.recoil.org:
ssh jon@jon.recoil.org 'cd /var/www/jon.recoil.org && tar jxvf ~/site.tar.bz2'

