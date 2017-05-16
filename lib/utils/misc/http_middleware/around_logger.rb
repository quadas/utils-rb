# Write usefull logs when request and response
#
# ==== Example
#   conn = Faraday.new(url: 'http://quadas.com') do |f|
#     f.use :around_logger do |logger|
#       logger.tagged 'SSP Audit', 'Nex'
#       # Logs "[SSP Audit] [Nex] Started POST: http://..."
#     end
#     f.adapter  Faraday.default_adapter
#   end
module Utils
  module Misc
    module HTTPMiddleware
      class AroundLogger < Faraday::Middleware

        def initialize(app, logger = Rails.logger)
          super(app)
          @logger = logger
          yield self if block_given?
        end

        def call(request_env)
          started_at = Time.now
          @logger.info "#{tags_text}Started #{request_env[:method].to_s.upcase}: #{request_env[:url]} at #{Time.now}"
          @logger.info "#{tags_text}Headers: #{request_env[:request_headers]}"
          @logger.info "#{tags_text}Request body: #{request_env[:body]}"
          @app.call(request_env).on_complete do |response_env|
            ended_at   = Time.now
            @logger.info "#{tags_text}Completed #{response_env[:status]} in #{((ended_at - started_at)* 1000).to_i}ms"
          end
        end

        def tagged(*tags)
          @tags = tags.flatten.reject(&:blank?)
        end

        private

        def tags_text
          if @tags.any?
            @tags.collect { |tag| "[#{tag}] " }.join
          end
        end
      end
    end
  end
end
