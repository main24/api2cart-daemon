require 'spec_helper'

describe Api2cart::Daemon, '#total_request_quota' do
  subject { Api2cart::Daemon.total_request_quota }

  context 'when no quota defined' do
    it 'returns default value' do
      expect(subject).to eq(20)
    end
  end

  context 'when quota defined' do
    context 'via config' do
      before do
        Api2cart::Daemon.total_request_quota = 30
      end

      it 'returns configured value' do
        expect(subject).to eq(30)
      end

      context 'when env variable is also defined' do
        before do
          ENV['API2CART_DAEMON_TOTAL_REQUEST_QUOTA'] = '120'
        end

        it 'still returns configured value' do
          expect(subject).to eq(30)
        end

        after do
          ENV['API2CART_DAEMON_TOTAL_REQUEST_QUOTA'] = nil
        end
      end
    end

    context 'via ENV variable' do
      before do
        Api2cart::Daemon.total_request_quota = nil
        ENV['API2CART_DAEMON_TOTAL_REQUEST_QUOTA'] = '120'
      end

      it 'returns value from ENV' do
        expect(subject).to eq(120)
      end

      after do
        ENV['API2CART_DAEMON_TOTAL_REQUEST_QUOTA'] = nil
      end
    end
  end
end
