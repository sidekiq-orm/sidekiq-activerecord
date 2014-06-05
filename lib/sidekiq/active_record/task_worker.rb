module Sidekiq
  module ActiveRecord
    class TaskWorker < Sidekiq::Orm::TaskWorker

      def fetch_model(identifier, *args)
        self.class.model_class.find_by(self.class.identifier_key => identifier)
      end

      class << self

        protected

        def task_model_base_class
          ::ActiveRecord::Base
        end

      end

    end
  end
end
