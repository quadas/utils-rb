require 'spec_helper'

describe Utils::Misc::HTTPMiddleware::AroundLogger do
  let(:logger) { double('logger') }

  def make_middleware(options = {})
    described_class.new(lambda{|env| Faraday::Response.new(env)}, options) do |logger|
      logger.tagged 'SSP Audit', 'Nex'
    end
  end

  def perform(headers:, body:, middleware_options: { logger: logger })
    env = {
      method: :get,
      url: URI('http://example.com/'),
      request_headers: Faraday::Utils::Headers.new.update(headers),
      response_headers: Faraday::Utils::Headers.new(headers),
      body: body,
      status: 200
    }
    make_middleware(middleware_options).call(env)
  end

  context 'request with AroundLogger middleware' do
    context 'when write_body not enabled' do
      it 'write usefull logs without response body' do
        expect(logger).to receive(:info).with(/\[SSP Audit\] \[Nex\] Started GET: http:\/\/example.com\/ at /).ordered
        expect(logger).to receive(:info).with('[SSP Audit] [Nex] Headers: {"mock-header"=>"mock-header"}').ordered
        expect(logger).to receive(:info).with('[SSP Audit] [Nex] Request body: body').ordered
        expect(logger).not_to receive(:info).with(/\[SSP Audit\] \[Nex\] Response body:/)
        expect(logger).to receive(:info).with(/\[SSP Audit\] \[Nex\] Completed/).ordered

        perform(headers: { 'mock-header' => 'mock-header' }, body: 'body', middleware_options: { logger: logger })
      end
    end

    context 'when write_body enabled' do
      context 'when threshold assigned' do
        it 'write body when under assigned threshold' do
          expect(logger).to receive(:info).exactly(3).times
          expect(logger).to receive(:info).with(/\[SSP Audit\] \[Nex\] Response body:/).ordered
          expect(logger).to receive(:info).ordered

          perform(headers: { 'content-length' => 99 }, body: 'body', middleware_options: { logger: logger, write_body: { threshold: 100 } })
        end

        it 'write body when over assigned threshold' do
          expect(logger).to receive(:info).exactly(3).times
          expect(logger).not_to receive(:info).with(/\[SSP Audit\] \[Nex\] Response body:/)
          expect(logger).to receive(:info).ordered

          perform(headers: { 'content-length' => 101 }, body: 'body', middleware_options: { logger: logger, write_body: { threshold: 100 } })
        end
      end

      context 'when threshold not assign' do
        it 'write body when under default threshold' do
          expect(logger).to receive(:info).exactly(3).times
          expect(logger).to receive(:info).with(/\[SSP Audit\] \[Nex\] Response body:/).ordered
          expect(logger).to receive(:info).ordered

          perform(headers: { 'content-length' => 100 }, body: 'body', middleware_options: { logger: logger, write_body: true })
        end

        it 'will not write body when over default threshold' do
          expect(logger).to receive(:info).exactly(3).times
          expect(logger).not_to receive(:info).with(/\[SSP Audit\] \[Nex\] Response body:/)
          expect(logger).to receive(:info).ordered

          perform(headers: { 'content-length' => 300 }, body: 'body', middleware_options: { logger: logger, write_body: {} })
        end
      end
    end
  end
end
