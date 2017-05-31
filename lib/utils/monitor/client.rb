require 'ostruct'
require 'prometheus/client'
require 'prometheus/client/rack/exporter'
require 'prometheus/client/rack/collector'

require 'utils/monitor/client/middleware'

module Utils
  module Monitor
    module Client
      module_function

      def configure
        return @configure unless block_given?

        @configure = OpenStruct.new.tap { |c| yield(c) }
      end

      # System
      %i(memory cpu).each do |d|
        define_method(d) do |v|
          gauge = Prometheus::Client.registry.get(d) || Prometheus::Client.registry.gauge(d, "#{d} Cost")
          gauge.set({ platform: configure.platform,
                      category: configure.category,
                      ts: Time.now.to_i,
                      worker: "worker-#{configure.worker}" }, v)
        end
      end
    end
  end
end
