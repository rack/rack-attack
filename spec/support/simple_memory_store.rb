# frozen_string_literal: true

# Simple in-memory cache store for testing without ActiveSupport dependency
class SimpleMemoryStore
  def initialize
    @data = {}
  end

  def read(key)
    entry = @data[key]
    return nil unless entry
    return nil if entry[:expires_at] && entry[:expires_at] < Time.now

    entry[:value]
  end

  def write(key, value, options = {})
    expires_at = options[:expires_in] ? Time.now + options[:expires_in] : nil
    @data[key] = { value: value, expires_at: expires_at }
    true
  end

  def increment(key, amount = 1, options = {})
    current = read(key)
    if current.nil?
      nil
    else
      new_value = current.to_i + amount
      write(key, new_value, options)
      new_value
    end
  end

  def delete(key)
    @data.delete(key)
  end

  def delete_matched(matcher)
    @data.keys.each do |key|
      @data.delete(key) if key.match?(matcher)
    end
  end

  def clear
    @data.clear
  end
end
