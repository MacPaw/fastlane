require 'faraday'

require_relative 'globals'

module Spaceship
  class SizeStatsMiddleware < Faraday::Middleware
    class << self
      def url_stats
        @url_stats ||= {}
      end
    end

    def initialize(app)
      super(app)
    end

    DEFAULT_STATS = {
      duration: 0,
      size: 0,
      calls_count: 0
    }

    def call(request_env)
      started_at = Time.now

      response = @app.call(request_env)

      ended_at = Time.now

      parsed = URI.parse(response.env.url.to_s)
      clear_url = "#{parsed.scheme}://#{parsed.host}#{parsed.path}"

      duration = ended_at - started_at
      size = 0
      size = response.body.length if response.body

      SizeStatsMiddleware.url_stats[clear_url] ||= DEFAULT_STATS.dup

      SizeStatsMiddleware.url_stats[clear_url][:duration] += duration
      SizeStatsMiddleware.url_stats[clear_url][:size] += size
      SizeStatsMiddleware.url_stats[clear_url][:calls_count] += 1

      response
    rescue => e
      puts("Failed to log spaceship stats - #{e.message}") if Spaceship::Globals.verbose?
    end
  end
end
