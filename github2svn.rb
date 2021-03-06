#!/usr/bin/env ruby

require 'sinatra'
require 'json'

GIT_DIR = File.expand_path(File.join('~', 'git'))

def log message
  puts "#{$$}: " + message
end

def git_dir repository
  File.join(GIT_DIR, repository)
end

def run command
  system command
  raise "Execution of '#{command}' failed with return code #{$?}" unless $? == 0
end

post '/' do
  push = JSON.parse(params[:payload])
  raise "Bad payload, missing 'repository': #{push.inspect}" unless push['repository']
  url = push['repository']['url']
  raise "Bad payload, missing 'repository'->'url': #{push.inspect}" unless url
  repository = url.gsub('http://github.com/', '').gsub('https://github.com/', '')
  
  log "Received push notification for repository #{repository}"
  raise "git checkout for #{repository} doesn't exist in #{git_dir repository}, please create one" unless File.exist?(git_dir(repository))
  
  log "Updating #{repository} from github"
  run "cd #{git_dir repository}; git fetch && git rebase origin/master"
  
  log "Pushing updates up to SVN"
  run "cd #{git_dir repository}; git svn rebase && git svn dcommit"
  
  log "Done."
end
