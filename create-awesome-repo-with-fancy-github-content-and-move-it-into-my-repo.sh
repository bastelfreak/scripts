#!/bin/bash

# created by Tim 'bastelfreak' Meusel
# stolen parts are from http://blog.tomasjansson.com/automatic_creation_of_repository_when_using_gitolite/
# $1 is repo URL like https://github.com/adrienthebo/r10k.git
# we need gitolite-admin-node in our ssh config

##
# what do we do here?
# adding a repo to our gitolite service
# clone stuff from github
# change origin to our gitolite
# add github as upstream so further merging
##

working_dir="/home/bastelfreak/HE-puppet-admin-git"

# $1 is a full path to a github repo
get_origin_repo_name() {
  if [ -n "${1}" ]; then
    name=$(echo "${1}" | awk -F'/' '{print $NF}')
    echo "${name%.git}"
  fi
}

# we always want something like $author-$repo
# this is the default for repos from forge.puppetlabs.com
#
# okay, this idea sucks. why? because we are renaming the repos which will fuck up with the autoloader feature of puppet
# $1 has to be the full github path
get_new_repo_name() {
 get_origin_repo_name "${1}"
}

# $1 has to be the name of the new repo
add_repo() {
    if [ "$1" == "" ] ; then echo "[E] One arg is needed!"; return 1; 
else
        cd "${working_dir}/gitolite-admin/conf"
        echo -e "" >> gitolite.conf
        echo -e "repo ${1}" >> gitolite.conf
        echo -e "RW+ = @all" >> gitolite.conf
        cd ..
        git commit -am "Added repo ${1}"
        git push
    fi     
}

# $1 has to be the complete URL
make_magic_with_origin_repo() {
  cd "${working_dir}"
  git clone "${1}"
  origin="$(get_origin_repo_name ${1})"
  master="$(get_new_repo_name ${1})"
  cd "${origin}"
  git remote remove origin
  git remote add origin "gitolite-admin-node:${master}"
  git push --set-upstream origin master
  git push master origin
}

# $1 URL
add_upstream() {
  master="$(get_new_repo_name ${1})"
  cd "${working_dir}/${master}"
  git remote add upstream "${1}"
  git branch --set-upstream-to=origin/master
}

hui() {
  master="$(get_new_repo_name ${1})"
  add_repo "${master}"
  make_magic_with_origin_repo "${1}"
  git branch -va
  git remote -v
#  add_upstream "${1}"
}
