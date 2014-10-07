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
# How does it work?
# start the script with ./script modulename
# the setup method starts to analyse the given modulename,
# if we think we got a uniq modulename we will search it on forge.puppetlabs.com
# if it's a general name we will do a generic search and take the first hit if we just get one result
# 
# our recursively_mirror_repos method will add a new repo to our gitolite service (add_repo), then the module
# gets checked out and moved into our own repo. we are doing this recursivly for every module that is a dependency
##

##
# Well, this script finally works, look at the code for 'todo' for further improvements
##

require 'puppet_forge'
require 'git'
require 'net/ssh'
require 'yaml'

module ForgeClient

  PuppetForge.user_agent = 'Mozilla/5.0 (Windows NT 5.1; rv:5.0.1) Gecko/20100101 Firefox/5.0.1'
  @path = '/home/bastelfreak/HE-puppet-admin-git'
  @mngt_repo = 'gitolite-admin'
  @mngt_repo_path = "#{@path}/#{@mngt_repo}"
  @sshalias = 'gitolite-admin-node' # this is a alias in ~/.ssh/config
  @user = 'git'

  # this method will do a git checkout
  def self.clone_and_move(res)
    puts "we are know cloning #{res.name} from #{res.homepage_url} to #{@path}"
    g = Git.clone res.homepage_url, res.name, :path => @path
    g.remote('origin').remove
    g.add_remote 'origin', "#{@sshalias}:#{res.name}"
    g.push 'origin', 'master', :set_upstream => true
    puts "and we removed the old remote, added our own repo as origin and set it as upstream"
  end

  # checks if our gitolite already serves a suitable repo
  # otherwise create one
  def self.add_repo(res)
    repos = get_current_repos(connect_to_git('info'))
    unless repos.include?(res.name)
      puts "we don't own a repo called #{res.name}, we will add it"
      mngt_g = Git.open @mngt_repo_path
      f = File.open "#{@mngt_repo_path}/conf/gitolite.conf", 'a'
      f.write "repo #{res.name}\n"
      f.write "\tRW+ = @all\n"
      f.close
      mngt_g.commit_all "added repo #{res.name}"
      mngt_g.push
      puts "aaaaaand its added"
    end
  end

  # return a pretty list of all requiered modules
  def self.get_requirements(res)
    puts "lets get all the requirements for #{res.name}"
    release = res.releases.first
    deps = release.metadata['dependencies']
    #{"name"=>"puppetlabs/stdlib", "version_requirement"=>"4.1.x"}

  end

  # connects via ssh to our gitolite service
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
  def self.connect_to_git(cmd)
    #Net::SSH needs the user, even if it is already specified in our sshalias, bug?
    Net::SSH.start(@sshalias, @user) do |ssh|
      ssh.exec!(cmd)
    end
  end

# gets every repo from our get_current_repos()
def self.get_current_repos(output)
  unless output.empty?
    ary = []
    output = output.lines.to_a[2..-1].join
    output.each_line do |line|
      ary << line[/.*\t(.*)$/, 1]
    end
  end 
end

# connect to forge.puppetlabs.com API to get information about a specific module
def self.get_puppetforge_module(modulename)
  puts "connect to forge.puppetlabs.com because we want module #{modulename}"
  modulename.gsub!('/', '-')
  puts modulename
  res = PuppetForge::Module.find(modulename)
end

# search through forge.puppetlabs.com and returns all matching modules
def self.get_puppetforge_modules(modulename)
  puts "connect to forge.puppetlabs.com because we want to search for #{modulename}"
  PuppetForge::Module.where(query: modulename).all
end

  # wrapper function for recursion
  # clones a module into our own repo and every dependencies
  # todo:
  # handle dependencies based on module versions
  def self.recursively_mirror_repos(res)
    # for main repo + each repo in $dependencies do
    if add_repo res
      clone_and_move res
    else
      puts "we already own a repo named #{res.name}, won't clone it, but we are checking for deps"
    end
    deps = get_requirements res
    deps.each do |dep|
      puts "#{res.name} has the dependency #{dep}, we will continue with that"
      recursively_mirror_repos(get_puppetforge_module(dep['name']))
    end
  end

  # possible module names:
  # blaa # if we find only one suitable module, we take it, otherwise inspect
  # creator-blaa # directly take it
  # creator/blaa # mhm
  def self.setup(var)
    unless var.empty?
      if var.include?("-") || var.include?("/")
        res = get_puppetforge_module var
        puts "congratz, we found one module named #{res.name}, we will start to mirror it"
        recursively_mirror_repos res
      else
        result = get_puppetforge_modules var
        if result.total == 1
          res = result.first
          recursively_mirror_repos res
        else
          # todo:
          # we found more than one suitable module, print all and exit would be nice
          puts "oh nooooooes"
          puts result.to_yaml
        end
      end
    end
  end
end

# let the magic happen
require_relative 'forge_client.rb'
ForgeClient.setup ARGV[0].dup
