# frozen_string_literal: true

module Capistrano
  class Terraform

    def initialize(params = {})
      @path = nil
      @var = nil
      @var_file = nil
      @target = nil
      @after_publish = nil
      @deploy = nil
      @backend_config = nil
      update(params)
    end

    def update(params = {})
      # handle path updates
      @path = params[:path] if params.key?(:path)

      # handle var_file upserts
      if params.key?(:var_file)
        @var_file ||= []
        @var_file.push(params[:var_file])
        @var_file.flatten!
      end
      @var_file = nil if @var_file == []

      # handle var upserts
      if params.key?(:var)
        @var ||= []
        @var.push(params[:var])
        @var&.flatten!&.uniq!
      end
      @var = nil if @var == []

      # handle target upserts
      if params.key?(:target)
        @target ||= []
        @target.push(params[:target])
        @target&.flatten!&.uniq!
      end
      @target = nil if @target == []

      # handle after_publish upserts
      if params.key?(:after_publish)
        @after_publish = params[:after_publish]
      end
      @after_publish = nil unless @after_publish == true

      # handle deploy upserts
      if params.key?(:deploy)
        @deploy = params[:deploy]
      end
      @deploy = nil unless @deploy == false

      # handle backend_config upserts
      if params.key?(:backend_config)
        @backend_config ||= []
        @backend_config.push(params[:backend_config])
        @backend_config&.flatten!&.uniq!
      end
      @backend_config = nil if @backend_config == []
    end

    def to_hash
      return {
        path: @path,
        var: @var,
        var_file: @var_file,
        target: @target,
        backend_config: @backend_config,
        after_publish: @after_publish,
        deploy: @deploy,
      }.compact
    end

    def to_s
      return to_hash
    end

    def deploy?
      return @deploy != false
    end

    def targets
      targets_ary = []
      Terraforms.targets.each do |t|
        targets_ary << t
      end
      @target&.each do |t|
        targets_ary << t
      end
      return targets_ary.uniq
    end

    def plan_outfile
      # fetch :terraform_plan_outfile, 'tf.plan'
      'tf.plan'
    end

    def run_path
      return Terraforms.root_path.join(@path) if @path
      return Terraforms.root_path
    end

    def init_cmd_line
      cmd_ary = [Terraforms.terraform_cmd, :init]
      cmd_ary << fetch(:terraform_init_opts, [])
      cmd_ary << '-reconfigure' # always reconfigure to preserve states across stages

      root_relative = Terraforms.root_path.relative_path_from(run_path)
      fetch(:terraform_backend_config, []).uniq.each do |bec|
        if bec.include?('=')
          cmd_ary << "-backend-config='#{bec}'"
        else
          cmd_ary << "-backend-config='#{root_relative.join(bec)}'"
        end
      end

      @backend_config&.each do |bec|
        cmd_ary << "-backend-config='#{bec}'"
      end

      return cmd_ary.flatten
    end

    def plan_cmd_line
      cmd_ary = [Terraforms.terraform_cmd, :plan]
      cmd_ary << fetch(:terraform_plan_opts, [])
      cmd_ary << "-out='#{plan_outfile}'"

      root_relative = Terraforms.root_path.relative_path_from(run_path)

      fetch(:terraform_var_file, []).uniq.each do |tf_var_file|
        cmd_ary << "-var-file='#{root_relative.join(tf_var_file)}'"
      end

      fetch(:terraform_var, []).uniq.each do |tf_var|
        cmd_ary << "-var='#{tf_var}'"
      end

      @var_file&.each do |var_file|
        cmd_ary << "-var-file='#{var_file}'"
      end

      @var&.each do |var|
        cmd_ary << "-var='#{var}'"
      end

      targets.each do |target|
        cmd_ary << "-target='#{target}'"
      end

      return cmd_ary.flatten
    end

    def apply_cmd_line
      cmd_ary = [Terraforms.terraform_cmd, :apply]
      cmd_ary << fetch(:terraform_apply_opts, [])
      cmd_ary << "'#{plan_outfile}'"
      return cmd_ary.flatten
    end

    def create_tasks(terraform_id)
      create_init_task(terraform_id)
      create_plan_task(terraform_id)
      create_clean_task(terraform_id)
      create_apply_task(terraform_id)
    end

    def create_init_task(terraform_id)
      task = Rake::Task.define_task "terraform:#{terraform_id}:init" do
        terraform_obj = Terraforms.find(terraform_id)
        terraform_cmd = terraform_obj.init_cmd_line

        if roles(:terraform).first
          on roles(:terraform).first do |_terraform_remote|
            info "Running terraform:#{terraform_id}:init..."
            within terraform_obj.run_path do
              execute :pwd
              raise 'nyi'
            end
          end
        else
          run_locally do
            info "Running terraform:#{terraform_id}:init..."
            within terraform_obj.run_path do
              execute :pwd
              execute(*terraform_cmd)
            end
          end
        end
      end
      task.comment = "initialize specific terraform: #{terraform_id}"
    end

    def create_plan_task(terraform_id)
      task = Rake::Task.define_task "terraform:#{terraform_id}:plan" do
        terraform_obj = Terraforms.find(terraform_id)
        terraform_cmd = terraform_obj.plan_cmd_line

        if roles(:terraform).first
          on roles(:terraform).first do |_terraform_remote|
            info "Running terraform:#{terraform_id}:plan..."
            within terraform_obj.run_path do
              execute :pwd
              execute(*terraform_cmd)
            end
          end
        else
          run_locally do
            info "Running terraform:#{terraform_id}:plan..."
            within terraform_obj.run_path do
              execute :pwd
              execute(*terraform_cmd)
            end
          end
        end
      end
      task.comment = "plan specific terraform: #{terraform_id}"
    end

    def create_apply_task(terraform_id)
      task = Rake::Task.define_task "terraform:#{terraform_id}:apply" do
        terraform_obj = Terraforms.find(terraform_id)
        terraform_cmd = terraform_obj.apply_cmd_line

        if roles(:terraform).first
          on roles(:terraform).first do |_terraform_remote|
            info "Running terraform:#{terraform_id}:apply..."
            within terraform_obj.run_path do
              execute :pwd
              execute(*terraform_cmd)
            end
          end
        else
          run_locally do
            info "Running terraform:#{terraform_id}:apply..."
            within terraform_obj.run_path do
              execute :pwd
              execute(*terraform_cmd)
            end
          end
        end
      end
      task.comment = "apply specific terraform: #{terraform_id}"
    end

    def create_clean_task(terraform_id)
      task = Rake::Task.define_task "terraform:#{terraform_id}:clean" do
        terraform_obj = Terraforms.find(terraform_id)
        terraform_cmd = [:rm, '-rf', '.terraform', plan_outfile]

        if roles(:terraform).first
          on roles(:terraform).first do |_terraform_remote|
            info "Cleaning terraform:#{terraform_id}..."
            within terraform_obj.run_path do
              execute :pwd
              execute(*terraform_cmd)
            end
          end
        else
          run_locally do
            info "Cleaning terraform:#{terraform_id}:plan..."
            within terraform_obj.run_path do
              execute :pwd
              execute(*terraform_cmd)
            end
          end
        end
      end
      task.comment = "clean specific terraform: #{terraform_id}"
    end

  end
end
