require 'spec_helper'

describe Utils::Misc::HTTPMiddleware::ParamsPrepend do
  let(:json_content_type) { 'application/json' }
  let(:prepense_body) { {body1: 'body1', body2: 'body2'} }
  let(:prepense_params) { {param1: 'param1', param2: 'param2'} }
  let(:body_prepend_middleware) { described_class.new(lambda{|env| env}, body: prepense_body) }
  let(:params_prepend_middleware) { described_class.new(lambda{|env| env}, params: prepense_params) }

  def perform(middleware:, method:,  content_type: nil)
    env = {
      url: URI('http://example.com/'),
      method: method,
      request_headers: Faraday::Utils::Headers.new.update('content-type': content_type),
      body: ''
    }
    middleware.call(env)
  end

  context 'On :get, :head, :delete' do
    [:get, :head, :delete].each do |method|
      context "via #{method.upcase}" do
        let(:result) { perform(middleware: params_prepend_middleware, method: method, content_type: json_content_type) }

        it 'prepend params to url query' do
          expect(result[:url].query).to include('param1=param1&param2=param2')
        end
      end
    end
  end

  context 'On :post, :put' do
    [:post, :put].each do |method|
      context 'json request' do
        context "via #{method.upcase}" do
          let(:result) { perform(middleware: body_prepend_middleware, method: method, content_type: json_content_type) }

          it 'prepend params to url query' do
            expect(result[:body]).to eq(prepense_body.to_json)
          end
        end
      end

      context 'non-json request' do
        let(:result) { perform(middleware: body_prepend_middleware, method: method) }

        it 'prepend params to url query' do
          expect(result[:body]).to eq('body1=body1&body2=body2')
        end
      end
    end
  end

end
