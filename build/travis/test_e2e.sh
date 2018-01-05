#!/bin/bash
set -ue

export PATH="$(pwd)/vendor/bundle/ruby/2.4.0/bin:${PATH}"
export GEM_HOME="$(pwd)/vendor/bundle/ruby/2.4.0/"

gem build cli/kontena-cli.gemspec && \
  gem install --no-ri --no-rdoc *.gem

cd test && \
  bundle install --path vendor/bundle && \
  rake compose:setup && \
  rake
