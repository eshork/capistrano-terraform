# frozen_string_literal: true

set :terraform_plan_opts, ['-input=false']
set :terraform_init_opts, ['-input=false']
set :terraform_apply_opts, nil

namespace :terraform do
  desc 'initialize all terraform directories'
  task :init do
    ::Capistrano::Terraforms.all.each_pair do |terraform_id, terraform_obj|
      invoke "terraform:#{terraform_id}:init" if terraform_obj.deploy?
    end
  end

  desc 'plan all terraform directories'
  task :plan do
    ::Capistrano::Terraforms.all.each_pair do |terraform_id, terraform_obj|
      invoke "terraform:#{terraform_id}:plan" if terraform_obj.deploy?
    end
  end

  desc 'apply all planned terraform directories'
  task :apply do
    ::Capistrano::Terraforms.all.each_pair do |terraform_id, terraform_obj|
      invoke "terraform:#{terraform_id}:apply" if terraform_obj.deploy?
    end
  end

  desc 'clean all terraform directories'
  task :clean do
    ::Capistrano::Terraforms.all.each_pair do |terraform_id, terraform_obj|
      invoke "terraform:#{terraform_id}:clean" if terraform_obj.deploy?
    end
  end

  # desc 'clear all terraform initializations'
  # task :distclean

  # desc 'list all terraform directories'
  # task :list

end
