set :application, "PasswordPusher"
set :repository,  "git@github.com:pglombardo/PasswordPusher.git"

local_config = './config/deploy/local_cap_config.rb'
abort "\e[0;31mERROR: To use capistrano with PasswordPusher, create and populate a [config/deploy/local_cap_config.rb] file.  See [config/deploy/local_cap_config.rb.example]." unless File.exists?(local_config)

require local_config if File.exists?(local_config)

default_run_options[:pty] = true

set :scm, "git"
set :deploy_via, :remote_cache
set :use_sudo, false
ssh_options[:forward_agent] = true

# To fix the touching of assets
# # Bug/Fix: https://github.com/capistrano/capistrano/pull/121
set :normalize_asset_timestamps, false

set :stage, nil

desc "Run tasks in development environment"
task :development do
    set :stage, 'development'
    set :bundle_without,  [:production, :test, :preview]
    set :rails_env, 'development'
    default_environment['RAILS_ENV'] = 'development'
  
    # Development Config
    role :web, DEVELOPMENT_WEB
    role :app, DEVELOPMENT_APP
    role :console, DEVELOPMENT_CONSOLE
    role :db,  DEVELOPMENT_DB_HOST, :primary => true
    set :deploy_to, DEVELOPMENT_DEPLOY_TO
    set :user, DEVELOPMENT_USER
end

desc "Run tasks in staging environment"
task :staging do
    set :stage, 'staging'
    set :bundle_without,  [:test, :development, :preview]
    set (:bundle_cmd) { "/home/deployer/.rbenv/shims/bundle" }
    set :rails_env, 'staging'
    default_environment['RAILS_ENV'] = 'staging'

    # Staging Config
    role :web, STAGING_WEB
    role :app, STAGING_APP
    role :console, STAGING_CONSOLE
    role :db,  STAGING_DB_HOST, :primary => true
    set :deploy_to, STAGING_DEPLOY_TO
    set :user, STAGING_USER
end

desc "Run tasks in preview environment (customer preview)"
task :preview do
    set :stage, 'preview'
    set :bundle_without,  [:test, :development]
    set :rails_env, 'preview'
    default_environment['RAILS_ENV'] = 'preview'

    # Preview Config
    role :web, PREVIEW_WEB
    role :app, PREVIEW_APP
    role :console, PREVIEW_CONSOLE
    role :db,  PREVIEW_DB_HOST, :primary => true
    set :deploy_to, PREVIEW_DEPLOY_TO
    set :user, PREVIEW_USER
end

desc "Run tasks in production environment"
task :production do
    set :stage, 'production'
    set :rails_env, 'production'
    set (:bundle_cmd) { "/usr/local/rbenv/shims/bundle" }
    set :bundle_flags, "--deployment --quiet --binstubs"
    set :bundle_without,  [:test, :development, :preview, :engineyard]
    set :default_environment, {
      'RAILS_ENV' => 'production'
    }

    # Prompt to make really sure we want to deploy into prouction
    puts "\n\e[0;31m   ######################################################################" 
    puts "   #\n   #       Are you REALLY sure you want to run this in production?"
    puts "   #\n   #               Enter y/N + enter to continue\n   #"
    puts "   ######################################################################\e[0m\n" 
    proceed = STDIN.gets[0..0] rescue nil 
    exit unless proceed == 'y' || proceed == 'Y'  
  
    # Production Config
    role :web, PRODUCTION_WEB
    role :app, PRODUCTION_APP
    role :console, PRODUCTION_CONSOLE
    role :db,  PRODUCTION_DB_HOST, :primary => true
    set :deploy_to, PRODUCTION_DEPLOY_TO
    set :user, PRODUCTION_USER
end

before :deploy, :no_stage_abort
before "db:migrate", :no_stage_abort
before :console, :no_stage_abort

task :no_stage_abort do
  abort "\e[0;31mERROR: No stage specified. Please specify one of: development, staging, preview or production (e.g. 'cap development deploy')" if stage.nil?
end

set :branch do
  # Attempt natural order search
  default_tag = `git tag | awk -F - '{ print $2; }' |  sort -t. -k 1.1n -k 3.1n -k 2.1n`.split("\n").last
  default_tag = default_tag

  tag = Capistrano::CLI.ui.ask "Tag or branch to deploy (you can even use 'master'): [#{default_tag}] "
  tag = default_tag if tag.empty?
  tag
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

desc "Open a remote console."
task :console, :roles => :console do
  input = ''
  run "cd #{current_path} && /usr/local/rbenv/shims/bundle exec rails console #{ENV['RAILS_ENV']}" do |channel, stream, data|
    next if data.chomp == input.chomp || data.chomp == ''
    print data
    channel.send_data(input = $stdin.gets) if data =~ /:\d{3}:\d+(\*|>)/
  end
end

desc "tail production log files"
task :tail_logs, :roles => :app do
  run "tail -f #{shared_path}/log/#{stage}.log" do |channel, stream, data|
    trap("INT") { puts 'Interupted'; exit 0; }
    puts  # for an extra line break before the host name
    puts "#{channel[:host]}: #{data}"
    break if stream == :err
  end
end

after "deploy", "deploy:notifications"
namespace :deploy do
  desc "Notify all services that there was a deploy."
  task :notifications do
    traceview_deploy
  end

  desc "Notify TraceView of a deploy"
  task :traceview_deploy, :roles => :app do
    set :notification_msg, "Deployed to 'PasswordPusher' #{stage} branch #{branch}"
    puts "  ** Sending notification to TraceView for 'PasswordPusher'"
    run "if test -x /usr/bin/tlog; then /usr/bin/tlog -a \"Gameface\" -m \"#{notification_msg}\"; else echo \"WARNING: /usr/bin/tlog not found.  TraceView deploy notification not sent.\"; fi"      
  end
end

require './config/boot'
require "bundler/capistrano"
load 'deploy/assets'
require "./config/capistrano_database_yml"
require 'airbrake/capistrano'

