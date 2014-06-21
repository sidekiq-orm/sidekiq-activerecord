module Examples
  describe AliasUserTaskWorker do

    let(:logger)  { Log }
    let(:service_class)  { UserMailer }
    let(:other_param)  { 'new@email.com' }

    let(:task_worker_class)  { AliasUserTaskWorker }
    subject(:task_worker)  { AliasUserTaskWorker.new }

    def run_worker
      task_worker.perform(user.email, other_param)
    end

    before do
      allow(service_class).to receive(:update_email)
      allow(logger).to receive(:error)
    end

    context 'when the user is not found' do

      let(:unfound_email) { 'unfound@email.com' }

      it 'calls not_found_user' do
        expect(task_worker).to receive(:not_found_user).with(unfound_email).and_call_original
        task_worker.perform(unfound_email)
      end

      it 'calls the logger with the not found email' do
        task_worker.perform(unfound_email)
        expect(logger).to have_received(:error).with("User not found for email:#{unfound_email}")
      end
    end

    context 'when the user is found' do

      let(:user) { create(:user) }

      it 'calls should_perform_on_user?' do
        expect(task_worker).to receive(:should_perform_on_user?).and_call_original
        run_worker
      end

      it 'check if the user is active' do
        allow(task_worker).to receive(:user).and_return(user)
        expect(user).to receive(:active?).and_call_original
        run_worker
      end

      context 'when the user is active' do

        let(:user) { create(:user, :active) }

        it 'calls perform_on_user' do
          expect(task_worker).to receive(:perform_on_user).and_call_original
          run_worker
        end

        it 'calls the service class with the user' do
          run_worker
          expect(service_class).to have_received(:update_email).with(user, other_param)
        end
      end

      context 'when the user is inactive' do

        let(:user) { create(:user, :banned) }

        it 'ignores the user' do
          run_worker
          expect(service_class).to_not have_received(:update_email)
        end

        it 'calls did_not_perform_on_user' do
          expect(task_worker).to receive(:did_not_perform_on_user).and_call_original
          run_worker
        end

        it 'calls the logger with the inactive user' do
          run_worker
          expect(logger).to have_received(:error).with("User #{user.id} is invalid")
        end
      end
    end
  end
end
