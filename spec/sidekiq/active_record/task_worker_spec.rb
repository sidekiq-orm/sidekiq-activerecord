describe Sidekiq::ActiveRecord::TaskWorker do

  class UserTaskWorker < Sidekiq::ActiveRecord::TaskWorker
  end

  let!(:user) { create(:user, :active) }

  subject(:task_worker_class)  { UserTaskWorker }
  subject(:task_worker)  { UserTaskWorker.new }

  def run_worker
    task_worker.perform(user.id)
  end

  describe 'sidekiq_task_model' do

    context 'when the identifier_key is specified' do
      before do
        class UserTaskWorker
          sidekiq_task_model User
          sidekiq_task_options :identifier_key => :email
        end
      end

      after do
        class UserTaskWorker
          sidekiq_task_model nil
          sidekiq_task_options :identifier_key => :id
        end
      end

      it 'sets the identifier_key' do
        identifier = task_worker_class.send(:identifier_key)
        expect(identifier).to eq :email
      end

      it 'calls the perform_on_model with the model' do
        expect(task_worker).to receive(:perform_on_model)
        task_worker.perform(user.email)
      end
    end

    context 'when a sidekiq_options is specified' do

      before do
        class UserTaskWorker
          sidekiq_options :queue => :user_queue
        end
      end

      it 'sets the queue' do
        sidekiq_options = task_worker_class.send(:get_sidekiq_options)
        expect(sidekiq_options['queue']).to eq :user_queue
      end
    end

    context 'when the specified task model is not a class' do

      it 'raises an ArgumentError' do
        expect {
          task_worker_class.send(:sidekiq_task_model, :something_unrelated)
        }.to raise_error ArgumentError
      end
    end

    context 'when the specified task model is not an ActiveRecord class' do

      class NotActiveRecord; end

      it 'raises an ArgumentError' do
        expect {
          task_worker_class.send(:sidekiq_task_model, NotActiveRecord)
        }.to raise_error ArgumentError
      end
    end

    context 'when a ActiveRecord class is specified' do

      before do
        class UserTaskWorker
          sidekiq_task_model User
        end
      end

      it 'sets the model' do
        klass = task_worker_class.send(:model_class)
        expect(klass).to eq User
      end

      describe 'task_model' do
        it 'sets the model' do
          run_worker
          expect(task_worker.task_model).to eq user
        end

        it 'has an alias of `task_model` withe for the specified model name' do
          run_worker
          expect(task_worker.user).to eq user
        end
      end

    end

    context 'when an ActiveRecord class name is specified' do
      before do
        class UserTaskWorker
          sidekiq_task_model :user
        end
      end

      it 'sets the model' do
        klass = task_worker_class.send(:model_class)
        expect(klass).to eq User
      end

      describe 'task_model' do
        it 'sets the model' do
          run_worker
          expect(task_worker.task_model).to eq user
        end

        it 'has an alias of `task_model` withe for the specified model name' do
          run_worker
          expect(task_worker.user).to eq user
        end
      end

      context 'when the model is not found' do

        let(:trash_id) { user.id + 10 }

        def run_worker
          task_worker.perform(trash_id)
        end

        it 'calls the not_found_model hook' do
          expect(task_worker).to receive(:not_found_model).with(trash_id)
          run_worker
        end

        it 'skips the perform_on_model' do
          expect(task_worker).to_not receive(:perform_on_model)
          run_worker
        end

        describe 'method alias' do
          it 'has an alias of not_found_model hook with for the specified task model name' do
            expect(task_worker.not_found_user(trash_id)).to eq trash_id
          end
        end

      end

      context 'when the mode is found' do

        context 'when the model validation is specified' do
          it 'calls the model_valid? hook' do
            expect(task_worker).to receive(:model_valid?)
            run_worker
          end

          describe 'method alias' do

            let(:mock_result) { 1234 }

            before do
              class UserTaskWorker
                def user_valid?
                  1234
                end
              end
            end

            it 'has an alias of model_valid? hook with for the specified task model name' do
              run_worker
              expect(task_worker.user_valid?).to eq mock_result
            end
          end
        end

        context 'when the model is valid' do

          before do
            allow(task_worker).to receive(:model_valid?).and_return(true)
          end

          it 'calls the perform_on_model with the model' do
            expect(task_worker).to receive(:perform_on_model)
            run_worker
          end

          describe 'perform_on_model' do
            context 'when passing only the model identifier' do
              it 'calls the perform_on_model with the model' do
                expect(task_worker).to receive(:perform_on_model)
                run_worker
              end
            end

            context 'when passing additional arguments' do
              it 'calls the perform_on_model with the model' do
                expect(task_worker).to receive(:perform_on_model).with(user.email)
                task_worker.perform(user.id, user.email)
              end
            end

            describe 'method alias' do
              it 'has an alias of perform_on_model hook with for the specified task model name' do
                task_worker.perform(user.id)
                expect(task_worker.perform_on_user).to eq user
              end
            end

          end
        end

        context 'when the model is invalid' do

          before do
            allow(task_worker).to receive(:model_valid?).and_return(false)
          end

          it 'calls the invalid_model hook' do
            expect(task_worker).to receive(:invalid_model)
            run_worker
          end

          it 'skips the perform_on_model' do
            expect(task_worker).to_not receive(:perform_on_model)
            run_worker
          end

          describe 'method alias' do
            it 'has an alias of invalid_model hook with for the specified task model name' do
              run_worker
              expect(task_worker.invalid_user).to eq user
            end
          end

        end

      end
    end
  end
end
