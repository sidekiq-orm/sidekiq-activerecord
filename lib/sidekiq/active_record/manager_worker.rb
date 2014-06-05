module Sidekiq
  module ActiveRecord
    class ManagerWorker < Sidekiq::Orm::ManagerWorker

      class << self

        def find_in_batches(models)
          models.find_in_batches(batch_size: batch_size) do |batch|
            yield batch
          end
        end

        def prepare_models_query(models_query)
          selected_attributes = [models_query.primary_key.to_sym, identifier_key, additional_keys].uniq
          models_query.select(selected_attributes)
        end

      end

    end
  end
end
