require 'spec_helper'

describe Sidekiq::TaskWorker do

  class UserTaskWorker
    include Sidekiq::TaskWorker

    sidekiq_task_model :user # or UserModel
    sidekiq_task_options :identifier_key => :token,
                         :model_class => :user

    def perform_on_model(user, email_type)
      UserMailer.deliver_registration_confirmation(user, email_type)
    end

    def not_found_model(token)
      Log.error "User not found for token:#{token}"
    end

    def model_valid?(user)
      user.active?
    end

    def invalid_model(user)
      Log.error "User #{user.token} is invalid"
    end
  end


  let!(:user) { create(:user, :active) }

  subject(:task_worker)  {UserTaskWorker }

  def run_worker
    task_worker.perform(user.id)
  end


  describe 'sidekiq_task_model' do

    context 'when a Class is specified' do

    end

    context 'when a class name is specified' do

    end

  end

  context 'when the model is not found' do
    it 'calls the not_found_model hook'
    it 'skips the perform_on_model'

  end

  context 'when the mode is found' do

    context 'when the model validation is specified' do

      it 'calls the model_valid? hook'

    end

    context 'when the model is valid' do

      it 'calls the perform_on_model with the model'

      describe 'perform_on_model' do

        context 'when passing only the model identifier' do

        end

        context 'when passing additional arguments' do

        end

      end
    end

    context 'when the model is invalid' do

      it 'calls the invalid_model hook'
      it 'skips the perform_on_model'

    end

  end

end
