require 'active_support/backtrace_cleaner'
require 'prometheus/client'

class ExceptionNotifier
  CUSTOM_COUNTER_KEY = :http_exceptions_total

  class << self
    # The argument `options` cannot be eliminated for cocern of compatibility
    def notify_exception(e, options={})
      custom_counter.increment(exception: e.class.name,
                               platform: settings.platform,
                               category: settings.category,
                               worker: "worker-#{settings.worker}",
                               backtrace: neat_backtrace(e),
                               ts: Time.now.to_i,
                               message: options.dig(:data, :message) || e.message)
    end

    def neat_backtrace(exception)
      return '' unless exception.backtrace
      bc.clean(exception.backtrace).first(3).join('|')
    end

    def bc
      return @bc if @bc

      @bc = ActiveSupport::BacktraceCleaner.new
      @bc.add_filter { |line| line.gsub(%r{\A.*/(.*)\z}, '\1') }
      @bc
    end

    def custom_counter
      return @e_counter if @e_counter

      Prometheus::Client.registry.get(CUSTOM_COUNTER_KEY) || init_custom_counter
    end

    def init_custom_counter
      Prometheus::Client.registry.counter(
        CUSTOM_COUNTER_KEY,
        'A counter of the total number of exceptions raised.'
      )
    end

    def settings
      Utils::Monitor::Client.configure
    end
  end
end
