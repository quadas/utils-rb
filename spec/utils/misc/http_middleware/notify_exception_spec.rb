require 'spec_helper'

describe Utils::Misc::HTTPMiddleware::NotifyException do
  let(:middleware) { described_class.new(lambda{|env| Faraday::Response.new(env)}) }

  def make_env(status:, body: '')
    {
      method: :get,
      url: URI('http://example.com/'),
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
          Object.send(:remove_const, :ExceptionNotifier)
          ExceptionNotifier = double('ExceptionNotifier')
          expect(ExceptionNotifier).not_to receive(:notify_exception)
          perform(status: status_code)
        end
      end
    end

    context 'when get failure response' do
      %w(406 408 422 500 503).each do |status_code|
        it "not notify exception when status is #{status_code}" do
          Object.send(:remove_const, :ExceptionNotifier)
          ExceptionNotifier = double('ExceptionNotifier')
          body = "body in notify exception with #{status_code}"
          env = make_env(status: status_code, body: body)
          expect(ExceptionNotifier).to receive(:notify_exception).with(Utils::Misc::HTTPMiddleware::NotifyException::ExternalRequestError.new(env.to_hash))
          perform(status: status_code, body: body)
        end
      end
    end
  end
end
