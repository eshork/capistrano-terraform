# frozen_string_literal: true

# Augments the standard Capistrano DSL with terraform specific methods

module Capistrano
  module DSL
    module Env
      def terraform(terraform_id, params = {})
        _terraform_upsert(terraform_id, params)
      end

      private

      def _terraform_upsert(terraform_id, params)
        return ::Capistrano::Terraforms.upsert(terraform_id, params)
      end

    end
  end
end
