module Utils
  module Monitor
    module Client
      module Middleware
        class Collector < Prometheus::Client::Rack::Collector
          protected

          def trace(env)
            start = Time.now
            yield.tap do |response|
              duration = (Time.now - start).to_f
              record(labels(env, response), duration)
            end
          rescue => exception
            ExceptionNotifier.notify_exception(exception)
            raise
          end
        end
      end
    end
  end
end
