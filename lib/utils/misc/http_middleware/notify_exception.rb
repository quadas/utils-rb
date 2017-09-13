# Write the useful info to log when http request failed
# Ref:
# https://github.com/lostisland/faraday/blob/master/lib/faraday/response/raise_error.rb
#
# ==== Example
#   conn = Faraday.new(url: 'http://quadas.com') do |f|
#     f.response :notify_exception, logger: Sidekiq.logger # default logger is Rails.logger
#     f.adapter  Faraday.default_adapter
#   end
require 'active_support/core_ext/object/blank'
require 'logger'

module Utils
  module Misc
    module HTTPMiddleware
      class NotifyException < Faraday::Response::Middleware
        ExternalRequestError = Class.new(StandardError)

        def initialize(app, logger: nil)
          super(app)
          @logger = logger || (defined?(Rails) ? ::Rails.logger : ::Logger.new(STDOUT))
        end

        def call(request_env)
          started_at = Time.now
          @app.call(request_env).on_complete do |response_env|
            ended_at   = Time.now
            case response_env[:status]
            when 404
              raise Faraday::Error::ResourceNotFound, response_values(response_env)
            when 407
              # mimic the behavior that we get with proxy requests with HTTPS
              raise Faraday::Error::ConnectionFailed, %{407 "Proxy Authentication Required "}
            when 400..600
              @logger.error <<~LOG
                \nHTTP request failed:
                [url]: #{request_env[:method].upcase}: #{request_env[:url]}
                [duration]: #{((ended_at - started_at) * 1000).to_i}ms
                [request header]: #{request_env[:request_headers]}
                [request body]: #{request_env[:body].presence || 'Empty'}
                [response status]: #{response_env[:status]}
                [response headers]: #{response_env[:response_headers]}
                [response body]: #{response_env[:body].presence || 'Empty'}
              LOG
            end
          end
        end

        private

        def response_values(env)
          {:status => env.status, :headers => env.response_headers, :body => env.body}
        end
      end
    end
  end
end
