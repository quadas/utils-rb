require 'spec_helper'

describe Utils::Misc::HTTPMiddleware::NotifyException do
  let(:logger) { double('logger') }
  let(:middleware) { described_class.new(lambda{|env| Faraday::Response.new(env)}, logger: logger) }

  def make_env(status:, body: '')
    {
      method: :get,
      url: URI('http://example.com/'),
      request_headers: Faraday::Utils::Headers.new('x-request-id' => '1'),
      response_headers: Faraday::Utils::Headers.new('x-response-id' => '1'),
      body: body,
      status: status.to_i
    }
  end

  def perform(status:, body: '')
    env = make_env(status: status, body: body)
    middleware.call(env)
  end

  context 'notify exception when necessary' do
    context 'when get successful response' do
      %w(200 201 204 302).each do |status_code|
        it "not notify exception when status is #{status_code}" do
          expect(logger).not_to receive(:error)
          perform(status: status_code)
        end
      end
    end

    context 'when get failure response' do
      %w(406 408 422 500 503).each do |status_code|
        it "not notify exception when status is #{status_code}" do
          body = "body in notify exception with #{status_code}"
          expect(logger).to receive(:error).with <<~LOG
            \nHTTP request failed:
            [url]: GET: http://example.com/
            [duration]: 0ms
            [request header]: #{{'x-request-id' => '1'}}
            [request body]: body in notify exception with #{status_code}
            [response status]: #{status_code}
            [response headers]: #{{'x-response-id' => '1'}}
            [response body]: body in notify exception with #{status_code}
          LOG
          perform(status: status_code, body: body)
        end
      end
    end
  end
end
