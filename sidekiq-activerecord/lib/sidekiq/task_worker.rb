require 'sidekiq/client'
require 'sidekiq/worker'

module Sidekiq
  module TaskWorker
    include Sidekiq::Worker

    module ClassMethods

      def perform(identifier)
        model = fetch_model(identifier)
        return not_found_model(identifier) unless model.present?

        if model_valid?(model)
          perform_on_model(model)
        else
          invalid_model(model)
        end
      end

      def perform_on_model(model)
        model
      end

      # recheck the if one of the items is still valid
      def model_valid?(model)
        true
      end

      # Hook to handel an invalid model
      def invalid_model(model)
      end

      # Hook to handel not found model
      def not_found_model(identifier)
      end

      def model_class
        raise NotImplementedError.new('`model_class` was not defined')
      end

      def identifier_key
        :id
      end

      
      private

      def fetch_model(identifier)
        model_class.find_by(identifier_key => identifier)
      end

    end

  end
end