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
# https://github.com/schacon/ruby-git/pull/163
##


##
# todo: 
# implement push upstream - done
# implement logiic - better
# implement get_requirements - replace / with - and return a hash
##

require 'puppet_forge'
require 'git'
require 'net/ssh'
require 'yaml'
class PuppetWrapper
  PuppetForge.user_agent = 'bastelfreak was here'
  @testmodule = 'lvm'
  @path = '/home/bastelfreak/HE-puppet-admin-git'
  @mngt_repo = 'gitolite-admin'
  @mngt_repo_path = "#{path}/#{mngt_repo}"
  @sshalias = 'gitolite-admin-node'
  @host = 'master.puppet.local'
  @user = 'git'
  @key = '/home/bastelfreak/.ssh/id_rsa_git_admin'

  # this method will do a git checkout
  def clone_and_move(res)
    g = Git.clone res.homepage_url, res.name, :path => path
    g.remote('origin').remove
    g.add_remote 'origin', "#{sshalias}:#{res.name}"
    g.push 'origin', 'master', :set_upstream => true
  end

  # checks if our gitolite already serves a suitable repo
  # otherwise create one
  def add_repo()
    repos = get_current_repos
    unless repos.include? res.name
      mngt_g = Git.open mngt_repo_path
      f = File.open "#{mngt_repo_path}/conf/gitolite.conf", 'a'
      f.write "repo #{res.name}\n"
      f.write "\tRW+ = @all\n"
      f.close
      mngt_g.commit_all "added repo #{res.name}"
      mngt_g.push
    end

  end

  # return a pretty list of all requierd modules
  def get_requirements
     unless release.metadata['dependencies'].empty?
    #=> [{"name"=>"puppetlabs/stdlib", "version_requirement"=>"4.1.x"}]

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
  def voodoo
    # for main repo + each repo in $dependencies do
    add_repo
    clone_and_move
  end

  result = PuppetForge::Module.where(query: testmodule).all
  if result.total == 1
    res = result.first
    voodoo res
  else
    puts result.inspect
  end
end

# possible module names:
# blaa # if we find only one suitable module, we take it, otherwise inspect
# creator-blaa # directly take it
# creator/blaa # mhm
def parse_var
  testmodule = ARGV[0]
  if testmodule.include? "-" || testmodule.include? "/"
    testmodule.gsub! '/' '-'
    res = PuppetForge::Module.find(testmodule)
  else
    result = PuppetForge::Module.where(query: testmodule).all
    if result.total == 1
      res = result.first
    else
      puts "oh nooooooes"
      puts result.to_yaml
    end
  end
end
