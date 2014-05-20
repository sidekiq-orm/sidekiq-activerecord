require 'spec_helper'

describe Sidekiq::TaskWorker do

  class UserTaskWorker
    include Sidekiq::TaskWorker
  end

  let!(:user) { create(:user, :active) }

  subject(:task_worker)  {UserTaskWorker }

  def run_worker
    task_worker.perform(user.id)
  end


  describe 'sidekiq_task_model' do

    context 'when a Class is specified' do

      before do
        class UserTaskWorker
          sidekiq_task_model User
        end
      end

      it 'sets the model' do
        klass = subject.send(:model_class)
        expect(klass).to eq User
      end

    end

    context 'when a class name is specified' do
      before do
        class UserTaskWorker
          sidekiq_task_model :user
        end
      end

      it 'sets the model' do
        klass = subject.send(:model_class)
        expect(klass).to eq User
      end

      context 'when the model is not found' do

        let(:trash_id) { user.id + 10 }

        def run_worker
          task_worker.perform(trash_id)
        end

        it 'calls the not_found_model hook' do
          expect(subject).to receive(:not_found_model).with(trash_id)
          run_worker
        end

        it 'skips the perform_on_model' do
          expect(subject).to_not receive(:perform_on_model)
          run_worker
        end
      end

      context 'when the mode is found' do

        context 'when the model validation is specified' do
          it 'calls the model_valid? hook' do
            expect(subject).to receive(:model_valid?).with(user)
            run_worker
          end
        end

        context 'when the model is valid' do

          before do
            allow(task_worker).to receive(:model_valid?).and_return(true)
          end

          it 'calls the perform_on_model with the model' do
            expect(task_worker).to receive(:perform_on_model).with(user)
            run_worker
          end

          describe 'perform_on_model' do
            context 'when passing only the model identifier' do
              it 'calls the perform_on_model with the model' do
                expect(task_worker).to receive(:perform_on_model).with(user)
                run_worker
              end
            end

            context 'when passing additional arguments' do
              it 'calls the perform_on_model with the model' do
                expect(task_worker).to receive(:perform_on_model).with(user, user.email)
                task_worker.perform(user.id, user.email)
              end
            end

          end
        end

        context 'when the model is invalid' do

          before do
            allow(task_worker).to receive(:model_valid?).and_return(false)
          end

          it 'calls the invalid_model hook' do
            expect(task_worker).to receive(:invalid_model).with(user)
            run_worker
          end

          it 'skips the perform_on_model' do
            expect(task_worker).to_not receive(:perform_on_model)
            run_worker
          end

        end

      end
    end
  end
end
