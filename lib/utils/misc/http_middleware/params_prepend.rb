# ==== Example
#   conn = Faraday.new(url: 'http://quadas.com') do |f|
#     # for POST request, prepend via body
#     f.request :params_prepend, body: { a: 'a', b: 'b' }
#
#     # for GET request, prepend via params
#     f.request :params_prepend, params: { a: 'a', b: 'b' }
#     f.adapter  Faraday.default_adapter
#   end
module Utils
  module Misc
    module HTTPMiddleware
      class ParamsPrepend < Faraday::Middleware
        CONTENT_TYPE = 'Content-Type'.freeze
        JSON_MIME = 'application/json'.freeze

        def initialize(app, options = {})
          super(app)
          @params = options[:body].presence || options[:params].presence
        end

        def call(env)
          if @params.present?
            case env[:method]
            when :post, :put
              inject_body(env)
            when :get, :head, :delete
              inject_url(env)
            end
          end
          @app.call env
        end

        private

        def inject_body(env)
          if env[:request_headers][CONTENT_TYPE] == JSON_MIME
            prev_body = (JSON.parse(env[:body]) rescue {})
            env[:body] = @params.merge(prev_body).to_json
          else
            prev_body = Faraday::Utils.parse_nested_query(env[:body]).to_h
            env[:body] = Faraday::Utils.build_nested_query(@params.merge(prev_body))
          end
        end

        def inject_url(env)
          prev_params = Faraday::Utils.parse_nested_query(env[:url].query).to_h
          env[:url].query = Faraday::Utils.build_nested_query(@params.merge(prev_params))
        end
      end
    end
  end
end
