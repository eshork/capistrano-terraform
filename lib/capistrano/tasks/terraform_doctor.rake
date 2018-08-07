# frozen_string_literal: true

# Add ourself to the standard 'cap <stage> doctor' invocation
task doctor: 'doctor:terraform'

# alias common misusage
task 'terraform:doctor' => 'doctor:terraform'

namespace :doctor do
  desc 'Display the effective terraform configuration'
  task :terraform do
    Capistrano::Doctor::TerraformDoctor.new.call
  end
end
