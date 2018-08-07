# frozen_string_literal: true

# include some special sauce
require_relative 'terraform/terraforms.rb'
require_relative 'terraform/terraform.rb'

# include our DSL updates
require_relative 'terraform/dsl.rb'

# include standard tasks and cap flow hooks
require_relative 'terraform/tasks'
require_relative 'terraform/hooks'
require_relative 'terraform/doctor'
