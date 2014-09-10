#!/usr/bin/ruby

##
# written by Tim 'bastelfreak' Meusel
# script for fetching git repos via puppet forge
##
# requirements:
# gem install git her puppet_forge typhoeus net-ssh
##
# Docs:
# https://github.com/puppetlabs/forge-ruby
# https://forgeapi.puppetlabs.com/
# https://github.com/schacon/ruby-git
# http://net-ssh.github.io/net-ssh/
##

require 'puppet_forge'
require 'git'
require 'net/ssh'

PuppetForge.user_agent = 'bastelfreak was here'
testmodule = 'kickstack'
path = '/home/bastelfreak/HE-puppet-admin-git'
sshalias = 'gitolite-admin-node'
host = 'master.puppet.local'
user = 'git'
key = '/home/bastelfreak/.ssh/id_rsa_git_admin'

# this function will do a git checkout
def clone(res)
  g = Git.clone res.homepage_url, res.name, :path => path
end

# checks if our gitolite already serves a suitable repo
# otherwise create one
def add_repo()
  repos = get_current_repos
  unless repos.include? res.name
    f = File.new "#{path}/gitolite-admin/conf/gitolite.conf", 'w+'
    f.write "repo #{res.name}\n"
    f.write "\t RW+ = @all\n"
    f.close
  end
end

# connects via ssh to our gitolite service and parses the output
# ssh output:
#hello bastelfreak, this is git@master running gitolite3 v3.6.1-6-gdc8b590 on git 1.8.3.1
#
# R W  gitolite-admin
# R W  kickstack
# R W  puppet-exportfact
# R W  puppet-pwgen
# R W  puppetlabs-concat
# R W  puppetlabs-lvm
# R W  puppetlabs-openstack
# R W  puppetlabs-stdlib
# R W  r10k-management
# R W  testing
def get_current_repos()
  ary = []
  Net::SSH.start(sshalias, user) do |ssh| #le wild bug occured. why do we have to specify the user?!
    output = ssh.exec!('info')
  end
  output = output.lines.to_a[2..-1].join
  output.each_line do |line|
    ary << line[/.*\t(.*)$/, 1]
  end
end

# wrapper function
def voodoo(res)  
  clone
end

result = PuppetForge::Module.where(query: testmodule).all
if result.total == 1
  res = result.first
  voodoo res
else
  puts result.inspect
end
