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
# the parse_var method starts to analyse the given modulename,
# if we think we got a uniq modulename we will search it on forge.puppetlabs.com
# if it's a general name we will do a generic search and take the first hit
# 
# our voodo method will add a new repo to our gitolite service (add_repo), then the module
# gets checked out and moved into our own repo. we are doing this recursivly for every module that is a dependencie
##

##
# todo: 
#   testing
#     add_repo - res.name doesn't work?
#     clone_and_move - not tested
#     parse_var - not completely tested
#     recursively_mirror_repos - well, should work, but not tested
# seems to work:
#   initialize
#   connect_to_git
#   get_current_repos
#   parse_var (tested only with valid module names)
##

require 'puppet_forge'
require 'git'
require 'net/ssh'
require 'yaml'

module PuppetWrapper

  def initialize
    PuppetForge.user_agent = 'bastelfreak was here'
    @testmodule = 'lvm'
    @path = '/home/bastelfreak/HE-puppet-admin-git'
    @mngt_repo = 'gitolite-admin'
    @mngt_repo_path = "#{@path}/#{@mngt_repo}"
    @sshalias = 'gitolite-admin-node'
    @user = 'git'
  end

  # this method will do a git checkout
  def clone_and_move(res)
    puts "we are know cloning #{res.name} from #{res.homepage_url} to #{@path}"
    g = Git.clone res.homepage_url, res.name, :path => @path
    g.remote('origin').remove
    g.add_remote 'origin', "#{@sshalias}:#{res.name}"
    g.push 'origin', 'master', :set_upstream => true
    puts "and we removed the old remote, added our own repo as origin and set it as upstream"
  end

  # checks if our gitolite already serves a suitable repo
  # otherwise create one
  def add_repo(res)
    repos = get_current_repos(connect_to_git('info'))
    p res
    name = res.name
    unless repos.include?(name)
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
  def get_requirements(res)
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
  def connect_to_git(cmd)
    ary = []
    #Net::SSH needs the user, even if it is already specified in our sshalias, bug?
    Net::SSH.start(@sshalias, @user) do |ssh|
      ssh.exec!(cmd)
    end
  end

# gets every repo from our get_current_repos()
def get_current_repos(output)
  unless output.empty?
    ary = []
    output = output.lines.to_a[2..-1].join
    output.each_line do |line|
      ary << line[/.*\t(.*)$/, 1]
    end
  end 
end

# connect to forge.puppetlabs.com API to get information about a specific module
def get_puppetforge_module(modulename)
  PuppetForge::Module.find(modulename)
end

# search through forge.puppetlabs.com and returns all matching modules
def get_puppetforge_modules(modulename)
  PuppetForge::Module.where(query: modulename).all
end

  # wrapper function for recursion
  # clones a module into our own repo and every dependencies
  # todo:
  # handle dependencies based on module versions
  def recursively_mirror_repos(res)
    # for main repo + each repo in $dependencies do
    if add_repo res
      clone_and_move res
    else
      puts "we already own a repo named #{res.name}, won't clone it, but we are checking for deps"
    end
    deps = get_requirements res
    deps.each do |dep|
      puts "#{res.name} has the dependency #{dep}, we will continue with that"
      recursively_mirror_repos(get_puppetforge_object(dep['name']))
    end
  end

  # possible module names:
  # blaa # if we find only one suitable module, we take it, otherwise inspect
  # creator-blaa # directly take it
  # creator/blaa # mhm
  def parse_var(var)
    unless var.empty?
      if var.include?("-") || var.include?("/")
        var.gsub! '/' '-'
        res = get_puppetforge_object var
        puts "congratz, we found one module names #{res.name}, we will start to mirror it"
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
PuppetWrapper.parse_var ARGV[0].dup
