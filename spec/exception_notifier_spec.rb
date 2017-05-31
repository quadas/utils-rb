require 'spec_helper'

describe ExceptionNotifier do
  let(:client) { double(:client) }

  before(:example) do
    Utils::Monitor::Client.configure do |config|
      config.platform = 'p'
      config.category = 'c'
      config.worker = 0
    end
    allow(Prometheus::Client).to receive_message_chain(:registry, :get).and_return client
  end

  it 'increases the counter' do
    params = hash_including(
      exception: 'StandardError',
      platform: 'p',
      category: 'c',
      worker: 'worker-0',
      message: 'asdf'
    )
    expect(client).to receive(:increment).with(params)
    ExceptionNotifier.notify_exception(StandardError.new('asdf'))
  end
end
