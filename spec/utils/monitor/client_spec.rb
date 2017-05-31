require 'spec_helper'

describe Utils::Monitor::Client do
  describe '#configure' do
    it 'accepts a block to define configuration instance' do
      Utils::Monitor::Client.configure do |config|
        config.platform = 'platform'
        config.category = 'dsp'
      end

      expect(Utils::Monitor::Client.configure.platform).to eq 'platform'
      expect(Utils::Monitor::Client.configure.category).to eq 'dsp'
    end
  end

  %i(cpu memory).each do |d|
    describe "##{d}" do
      let(:client) { double(:client) }

      before(:example) do
        Utils::Monitor::Client.configure do |config|
          config.platform = 'p'
          config.category = 'c'
          config.worker = 0
        end
        allow(Prometheus::Client).to receive_message_chain(:registry, :get).and_return client
      end

      it 'rewrites gauge' do
        expect(client).to receive(:set).with(hash_including(platform: 'p', category: 'c', worker: 'worker-0'), 60)
        Utils::Monitor::Client.send(d, 60)
      end
    end
  end
end
