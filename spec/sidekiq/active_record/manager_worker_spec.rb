describe Sidekiq::ActiveRecord::ManagerWorker do

  before do
    allow(Sidekiq::Client).to receive(:push_bulk)
  end

  class MockUserWorker; end

  let(:worker_class) { MockUserWorker }
  let(:sidekiq_client) { Sidekiq::Client }

  class UserManagerWorker < Sidekiq::ActiveRecord::ManagerWorker
    sidekiq_delegate_task_to MockUserWorker
  end

  let!(:user_1) { create(:user, :active) }
  let!(:user_2) { create(:user, :active) }
  let!(:user_3) { create(:user, :active) }
  let!(:user_4) { create(:user, :banned) }

  let(:models_query) { User.active }

  describe 'perform_query_async' do

    def run_worker(options = {})
      UserManagerWorker.perform_query_async(models_query, options)
    end

    def mock_options(options)
      UserManagerWorker.send(:sidekiq_manager_options, options)
    end

    def batch_args(*ids)
      {class: worker_class, args: ids.map{ |id| [id] }}
    end

    let(:model_ids) { [[user_1.id], [user_2.id], [user_3.id]] }

    context 'when a sidekiq_options is specified' do

      before do
        class UserManagerWorker
          sidekiq_options :queue => :user_manager_queue
        end
      end

      it 'sets the queue' do
        sidekiq_options = UserManagerWorker.send(:get_sidekiq_options)
        expect(sidekiq_options['queue']).to eq :user_manager_queue
      end
    end

    context 'when the worker_class is specified' do

      class MockCustomWorker; end

      let(:custom_worker_class) { MockCustomWorker }

      def batch_args(*ids)
        {class: custom_worker_class, args: ids.map{ |id| [id] }}
      end

      context 'as method arguments' do

        it 'pushes a bulk of all user ids for the specified worker_class' do
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_1.id, user_2.id, user_3.id) )
          run_worker({:worker_class => custom_worker_class})
        end
      end

      context 'as sidekiq_delegate_task_to' do

        around do |example|
          UserManagerWorker.send(:sidekiq_delegate_task_to, custom_worker_class)
          example.run
          UserManagerWorker.send(:sidekiq_delegate_task_to, worker_class)
        end

        it 'pushes a bulk of all user ids for the specified worker_class' do
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_1.id, user_2.id, user_3.id) )
          run_worker
        end
      end

    end

    context 'when the batch size is specified' do

      let(:batch_size) { 2 }

      context 'as method arguments' do
        it 'pushes a bulk of user ids batches' do
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_1.id, user_2.id) )
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_3.id) )
          run_worker({batch_size: batch_size})
        end
      end

      context 'as sidekiq_manager_options' do

        around do |example|
          mock_options(:batch_size => batch_size)
          example.run
          mock_options(:batch_size => Sidekiq::ActiveRecord::ManagerWorker::DEFAULT_BATCH_SIZE)
        end

        it 'pushes a bulk of user ids batches' do
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_1.id, user_2.id) )
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_3.id) )
          run_worker
        end
      end
    end

    context 'when the additional_keys are specified' do

      let(:additional_keys) { [:email, :status] }

      def batch_args(*users)
        {class: worker_class, args: users.map{ |user| [user.id, user.email, user.status] }}
      end

      context 'as method arguments' do
        it 'pushes a bulk of all user ids and additional_keys' do
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_1, user_2, user_3) )
          run_worker({additional_keys: additional_keys})
        end
      end

      context 'as sidekiq_manager_options' do
        around do |example|
          mock_options(:additional_keys => additional_keys)
          example.run
          mock_options(:additional_keys => [])
        end

        it 'pushes a bulk of all user ids and additional_keys' do
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_1, user_2, user_3) )
          run_worker
        end
      end

    end

    context 'when the identifier_key is specified' do

      def batch_args(*users)
        {class: worker_class, args: users.map{ |user| [user.email] }}
      end

      let(:identifier_key) { :email }

      context 'as method arguments' do
        it 'pushes a bulk of all user emails as the identifier_key' do
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_1, user_2, user_3) )
          run_worker({identifier_key: identifier_key})
        end
      end

      context 'as sidekiq_manager_options' do

        around do |example|
          mock_options(:identifier_key => identifier_key)
          example.run
          mock_options(:identifier_key => Sidekiq::ActiveRecord::ManagerWorker::DEFAULT_IDENTIFIER_KEY)
        end

        it 'pushes a bulk of all user emails as the identifier_key' do
          expect(sidekiq_client).to receive(:push_bulk).with( batch_args(user_1, user_2, user_3) )
          run_worker
        end
      end

    end

  end

end