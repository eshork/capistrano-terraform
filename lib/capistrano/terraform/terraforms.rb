# frozen_string_literal: true

require_relative 'terraform.rb'

module Capistrano
  class Terraforms

    def self.terraform_cmd
      fetch(:terraform_cmd, :terraform)
    end

    def self.root
      fetch :terraform_root, nil
    end

    def self.vars
      fetch :terraform_var, []
    end

    def self.var_files
      fetch(:terraform_var_file, []).uniq
    end

    def self.targets
      [fetch(:terraform_target, [])].flatten.uniq
    end

    def self.deploy
      fetch :terraform_deploy, true
    end

    def self.root_path
      if roles(:terraform).first
        return deploy_path.join(fetch(:current_directory, 'current')).join(fetch(:terraform_root, '.'))
      else
        return Pathname.new(fetch(:terraform_root, '.'))
      end

      # return deploy_path.join(fetch(:current_directory, 'current')) if build_dir.nil?
      # return Pathname.new(build_dir.strip) if build_dir.strip[0] == '/'
      # return deploy_path.join(fetch(:current_directory, 'current'), build_dir)
    end

    def self.upsert(terraform_id, params = {})
      @@terraforms ||= {} # auto-init class variable on usage
      terraform_id = terraform_id.to_sym
      if @@terraforms.key?(terraform_id)
        @@terraforms[terraform_id].update(params)
      else
        @@terraforms[terraform_id] = ::Capistrano::Terraform.new(params)
        @@terraforms[terraform_id].create_tasks(terraform_id)
      end
    end

    def self.all
      @@terraforms ||= {} # auto-init class variable on usage
      return @@terraforms
    end

    def self.find(terraform_id)
      return all[terraform_id]
    end

  end
end
