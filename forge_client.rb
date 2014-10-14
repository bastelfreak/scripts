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
# Well, this script finally works, look at the code for 'todo' for further improvements
##
# Version is 1.3 (2014-10-14)
# My Docs: https://blog.bastelfreak.de/?p=990
##

require 'puppet_forge'
require 'git'
require 'net/ssh'

module ForgeClient

  PuppetForge.user_agent = 'Mozilla/5.0 (Windows NT 5.1; rv:5.0.1) Gecko/20100101 Firefox/5.0.1'
  @path = '/home/bastelfreak/HE-puppet-admin-git'
  @mngt_repo = 'gitolite-admin'
  @mngt_repo_path = "#{@path}/#{@mngt_repo}"
  @sshalias = 'gitolite-admin-node' # this is an alias in ~/.ssh/config
  @user = 'git'

  # this method will do a git checkout
  def self.clone_and_move(res)
    puts "we are know cloning #{res.name} from #{res.homepage_url} to #{@path}"
    g = Git.clone res.homepage_url, res.name, :path => @path
    g.remote('origin').remove
    g.add_remote 'origin', "#{@sshalias}:#{res.name}"
    g.push 'origin', 'master', :set_upstream => true
    puts "and we removed the old remote, added our own repo as origin and set it as upstream"
    return true
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
  # 'dependencies' is a hash:
  # {"name"=>"puppetlabs/stdlib", "version_requirement"=>"4.1.x"}
  # we have to parse the version later
  def self.get_requirements(res)
    puts "lets get all the requirements for #{res.name}"
    release = res.releases.first
    deps = release.metadata['dependencies']
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
    Net::SSH.start(@sshalias, @user) do |ssh|
      ssh.exec!(cmd)
    end
  end

  # gets every repo from our gitolite service and return as array
  def self.get_current_repos(output)
    output.lines[2..-1].map {|s| s[/.*\t(.*)$/, 1] }
  end

  # connect to forge.puppetlabs.com API to get information about a specific module
  def self.get_puppetforge_module(modulename)
    puts "connect to forge.puppetlabs.com because we want module #{modulename}"
    PuppetForge::Module.find(modulename)
  end

  # search through forge.puppetlabs.com and returns all matching modules
  def self.get_puppetforge_modules(modulename)
    puts "connect to forge.puppetlabs.com because we want to search for #{modulename}"
    results = PuppetForge::Module.where(query: modulename).all
    ary = []
    results.total > 1 ? results.each do |result| ary << result.name end : results.first
  end

  # wrapperfunction for searching a module / getting a specific
  # always returns a hash
  def self.get_puppetforge(modulename)
    result = nil
    if modulename.include?('-') || modulename.include?('/')
      modulename.gsub!('/', '-')
      result = get_puppetforge_module modulename
    elsif result.nil?
      get_puppetforge_modules modulename
    end
  end

  # wrapper function for recursion
  # clones a module into our own repo and every dependencies
  # todo:
  # handle dependencies based on module versions
  def self.recursively_mirror_repos(res)
    if add_repo res
      clone_and_move res 
    else
      puts "we already own a repo named #{res.name}, won't clone it"
    end
    deps = get_requirements res
    deps.each do |dep|
      puts "#{res.name} has the dependency #{dep}, we will continue with that"
      recursively_mirror_repos(get_puppetforge(dep['name']))
    end
  end

  # main function that starts the mirroring of a specific module
  # or prints a list of modules that we could mirror
  def self.setup(var)
    res = get_puppetforge var
    if res.is_a? Array
      puts "we found the following modules:"
      res.each do |modulename| puts modulename end
      puts "please start the script again and specify one of the above modules"
    else
      puts "congratz, we found one module named #{res.name}, we will start to mirror it"
      recursively_mirror_repos res
    end
  end
end

# let the magic happen
if ARGV[0]
  ForgeClient.setup ARGV[0].dup 
else
  puts "please specify a module as $1 that you would like to mirror"
end
