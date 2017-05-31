# Checkout:
# https://github.com/lostisland/faraday/blob/master/lib/faraday/response/raise_error.rb
#
# ==== Example
#   conn = Faraday.new(url: 'http://quadas.com') do |f|
#     f.response :notify_exception
#     f.adapter  Faraday.default_adapter
#   end
module Utils
  module Misc
    module HTTPMiddleware
      class NotifyException < Faraday::Response::Middleware
        ExternalRequestError = Class.new(StandardError)
        def on_complete(env)
          case env[:status]
          when 404
            raise Faraday::Error::ResourceNotFound, response_values(env)
          when 407
            # mimic the behavior that we get with proxy requests with HTTPS
            raise Faraday::Error::ConnectionFailed, %{407 "Proxy Authentication Required "}
          when 400..600
            ExceptionNotifier.notify_exception(ExternalRequestError.new(env.to_hash))
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
