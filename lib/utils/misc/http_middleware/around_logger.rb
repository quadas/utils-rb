# Write usefull logs when request and response
#
# ==== Example
#   conn = Faraday.new(url: 'http://quadas.com') do |f|
#     f.use :around_logger, logger: Logger.new(..), write_body: { threshold: 100 } do |logger|
#       logger.tagged 'SSP Audit', 'Nex'
#       # Logs "[SSP Audit] [Nex] Started POST: http://..."
#     end
#     f.adapter  Faraday.default_adapter
#   end
module Utils
  module Misc
    module HTTPMiddleware
      class AroundLogger < Faraday::Middleware
        WRITE_RESPONSE_BODY_THRESHOLD = 200

        def initialize(app, options = {})
          super(app)
          @options = options
          @logger = options[:logger].presence || Rails.logger
          yield self if block_given?
        end

        def call(request_env)
          started_at = Time.now
          @logger.info "#{tags_text}Started #{request_env[:method].to_s.upcase}: #{request_env[:url]} at #{Time.now}"
          @logger.info "#{tags_text}Headers: #{request_env[:request_headers]}"
          @logger.info "#{tags_text}Request body: #{request_env[:body]}"
          @app.call(request_env).on_complete do |response_env|
            ended_at   = Time.now
            @logger.info "#{tags_text}Response body: #{response_env[:body]}" if write_body?(response_env[:response_headers]['content-length'])
            @logger.info "#{tags_text}Completed #{response_env[:status]} in #{((ended_at - started_at)* 1000).to_i}ms"
          end
        end

        def tagged(*tags)
          @tags = tags.flatten.reject(&:blank?)
        end

        private

        def tags_text
          @tags_text ||= begin
            if @tags.any?
              @tags.collect { |tag| "[#{tag}] " }.join
            end
          end
        end

        def write_body?(body_length)
          return false unless @options.key?(:write_body)
          return true if @options[:write_body] === true
          threshold = (@options[:write_body]&.[](:threshold).presence || WRITE_RESPONSE_BODY_THRESHOLD)
          body_length.to_i <= threshold.to_i
        end
      end
    end
  end
end
