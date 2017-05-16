require 'faraday'
require 'active_support/dependencies/autoload'

module Utils
  module Misc
    module HTTPMiddleware
      extend ActiveSupport::Autoload

      autoload :AroundLogger, 'utils/misc/http_middleware/around_logger'
      autoload :ParamsPrepend, 'utils/misc/http_middleware/params_prepend'
      autoload :NotifyException, 'utils/misc/http_middleware/notify_exception'

      Faraday::Middleware.register_middleware :around_logger => lambda { AroundLogger }
      Faraday::Request.register_middleware :params_prepend => lambda { ParamsPrepend }
      Faraday::Response.register_middleware :notify_exception => lambda { NotifyException }
    end
  end
end

Dir[File.expand_path('./http_middleware/*.rb', __FILE__)].each(&method(:require))
