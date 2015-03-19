# this is the code for jenkins to pull from a git repo and run rspec tests
#export RBENV_VERSION='2.0.0p353'

export BUNDLE_GEMFILE=.gemfiles/Gemfile.beaker
export RS_SET
export VM_PUPPET_VERSION
PATH="/usr/local/bin/:$PATH"
export http_proxy="http://proxy..de:3128"
export https_proxy="http://proxy..de:3128"
export HTTP_PROXY="http://proxy..de:3128"
export HTTPS_PROXY="http://proxy..de:3128"
PE=${VM_PUPPET_VERSION%%-*}
PE_VER=${VM_PUPPET_VERSION##*-}
 
if [ "$PE" = "PE" ]; then
  export IS_PE='true'
  export pe_dist_dir='/home/jenkins/puppet/'
  export pe_ver="${PE_VER}"
fi
find . -name Gemfile.beaker -exec sed -i.bak "s/^source 'https/source 'http/" {} \;
export RS_DEBUG=true
bundle install --path .vendor
bundle update
bundle exec rspec --format RspecJunitFormatter --out rspec.xml spec/acceptance/*_spec.rb
