# Dedicated Redis connection for the waiting room middleware.
# Separate from Rails.cache (which uses solid_cache_store) to handle
# high-throughput flash-sale scenarios without impacting general app caching.
#
# Uses Redis DB 1 by default to isolate from other Redis usage.
# Configure via WAITING_ROOM_REDIS_URL environment variable in production.

require "redis"
require "json"

module WaitingRoomRedis
  PREFIX = "wr:"

  class << self
    def connection
      @connection ||= Redis.new(
        url: ENV.fetch("WAITING_ROOM_REDIS_URL", "redis://localhost:6379/1"),
        timeout: 1,
        reconnect_attempts: 3
      )
    end

    # Read a key, returning parsed JSON or nil
    def get(key)
      raw = connection.get("#{PREFIX}#{key}")
      return nil unless raw
      JSON.parse(raw, symbolize_names: true)
    rescue Redis::BaseError, JSON::ParserError => e
      Rails.logger.warn("[WaitingRoomRedis] GET #{key} failed: #{e.message}")
      nil
    end

    # Write a key with optional TTL (in seconds)
    def set(key, value, ex: nil)
      json = value.to_json
      if ex && ex > 0
        connection.set("#{PREFIX}#{key}", json, ex: ex.to_i)
      else
        connection.set("#{PREFIX}#{key}", json)
      end
    rescue Redis::BaseError => e
      Rails.logger.warn("[WaitingRoomRedis] SET #{key} failed: #{e.message}")
    end

    # Delete a key
    def del(key)
      connection.del("#{PREFIX}#{key}")
    rescue Redis::BaseError => e
      Rails.logger.warn("[WaitingRoomRedis] DEL #{key} failed: #{e.message}")
    end

    # Check if Redis is available
    def available?
      connection.ping == "PONG"
    rescue Redis::BaseError
      false
    end
  end
end
