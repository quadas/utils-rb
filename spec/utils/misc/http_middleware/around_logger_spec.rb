require 'spec_helper'

describe Utils::Misc::HTTPMiddleware::AroundLogger do
  let(:logger) { double('logger') }
  let(:middleware) do
    described_class.new(lambda{|env| Faraday::Response.new(env)}, logger) do |logger|
      logger.tagged 'SSP Audit', 'Nex'
    end
  end

  def perform(headers:, body:)
    env = {
      method: :get,
      url: URI('http://example.com/'),
      request_headers: Faraday::Utils::Headers.new.update(headers),
      response_headers: Faraday::Utils::Headers.new(headers),
      body: body,
      status: 200
    }
    middleware.call(env)
  end

  context 'request with AroundLogger middleware' do
    it 'write usefull logs' do
      expect(logger).to receive(:info).with(/\[SSP Audit\] \[Nex\] Started GET: http:\/\/example.com\/ at /).ordered
      expect(logger).to receive(:info).with('[SSP Audit] [Nex] Headers: {"mock-header"=>"mock-header"}').ordered
      expect(logger).to receive(:info).with('[SSP Audit] [Nex] Request body: body').ordered
      expect(logger).to receive(:info).with(/\[SSP Audit\] \[Nex\] Completed/).ordered

      perform(headers: { 'mock-header' => 'mock-header' }, body: 'body')
    end
  end
end
