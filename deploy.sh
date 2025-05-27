#!/bin/bash

set -ex

sudo docker build . -t foo
img=$(sudo docker create foo)
sudo docker cp $img:/build/site.tar.bz2 .
scp site.tar.bz2 jon@jon.recoil.org:
ssh jon@jon.recoil.org 'cd /var/www/jon.recoil.org && tar jxvf ~/site.tar.bz2'

