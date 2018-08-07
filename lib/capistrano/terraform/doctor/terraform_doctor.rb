# frozen_string_literal: true

require 'capistrano/doctor/output_helpers'

module Capistrano
  module Doctor
    class TerraformDoctor
      include Capistrano::Doctor::OutputHelpers

      def call
        title('Terraform Globals')
        tf_globals = [
          { var: :terraform_root, resolver: ->{ ::Capistrano::Terraforms.root } },
          { var: :terraform_deploy, resolver: ->{ ::Capistrano::Terraforms.deploy } },
          { var: :terraform_var, resolver: ->{ ::Capistrano::Terraforms.vars } },
          { var: :terraform_var_file, resolver: ->{ ::Capistrano::Terraforms.var_files } },
          { var: :terraform_target, resolver: ->{ ::Capistrano::Terraforms.targets } },
        ]

        table(tf_globals) do |tf_global, row|
          vname = tf_global[:var]
          vvalue = nil
          if tf_global[:resolver]
            vvalue = tf_global[:resolver].call
          end

          row << ":#{vname}"
          row << 'nil' if vvalue.nil?
          if vvalue.is_a?(String)
            row << "\"#{vvalue}\""
          else
            row << vvalue
          end
        end
        puts

        all_terrforms = ::Capistrano::Terraforms.all
        title("Terraform Paths/Projects (#{all_terrforms.size})")
        table(all_terrforms) do |terraform, row|
          row << terraform[0].to_s
          row << terraform[1].to_s
        end
        puts
      end

    end
  end
end
