#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

PasswordPusher::Application.load_tasks

# Add version gem rake tasks
require 'rake/version_task'
Rake::VersionTask.new do |task|

    # set rake task to not tag
    task.with_git_tag = false
    
  end