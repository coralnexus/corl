#!/bin/bash
#-------------------------------------------------------------------------------

export DEVELOPMENT_BUILD='true'
export RUBY_RVM_VERSION='ruby-2.1'

#-------------------------------------------------------------------------------

echo "1. Initializing Git"
apt-get -y install git || exit 1

echo "1. Fetching CORL bootstrap source repository"
rm -Rf /tmp/corl-bootstrap
git clone https://github.com/coralnexus/corl-bootstrap.git /tmp/corl-bootstrap >/tmp/corl.bootstrap.log 2>&1 || exit 2

cd /tmp/corl-bootstrap
git submodule update --init --recursive >>/tmp/corl.bootstrap.log 2>&1 || exit 3

echo "2. Executing CORL bootstrap process..."
chmod 755 /tmp/corl-bootstrap/bootstrap.sh

/tmp/corl-bootstrap/bootstrap.sh || exit $?