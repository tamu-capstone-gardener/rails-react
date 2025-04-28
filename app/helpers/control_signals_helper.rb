# Helper methods for control signal handling
#
# This module provides utilities for formatting and converting durations
# between different time units for control signals
module ControlSignalsHelper
  # Formats a duration into a human-readable string
  #
  # @param amount [Integer, String] the numeric amount of time
  # @param unit [String] the time unit (e.g., "hour", "minute", "second", "day")
  # @return [String] formatted duration string with proper pluralization
  # @example
  #   format_duration(3, "hour") # => "3 hours"
  #   format_duration(1, "minute") # => "1 minute"
  def format_duration(amount, unit)
    amount = amount.to_i
    # nothing or zero → "0 seconds"
    return "0 #{unit.to_s.pluralize}" if amount <= 0

    # normalize to singular base (e.g. "hours" → "hour")
    base = unit.to_s.downcase.chomp("s")
    label = (amount == 1 ? base : base.pluralize)
    "#{amount} #{label}"
  end

  # Converts a duration to seconds
  #
  # @param amount [Integer, String] the numeric amount of time
  # @param unit [String] the time unit (e.g., "hour", "minute", "second", "day")
  # @return [Integer] equivalent number of seconds
  # @example
  #   format_duration_to_seconds(2, "hour") # => 7200
  #   format_duration_to_seconds(30, "minute") # => 1800
  def format_duration_to_seconds(amount, unit)
    n = amount.to_i
    return 0 if n <= 0

    case unit.to_s.downcase.chomp("s")
    when "day"    then n * 24 * 60 * 60
    when "hour"   then n *      60 * 60
    when "minute" then n *           60
    when "second" then n
    else n
    end
  end

  # Converts seconds to a formatted duration string in the specified unit
  #
  # @param seconds [Integer, String] number of seconds
  # @param unit [String] the target time unit (e.g., "hour", "minute", "second", "day")
  # @return [String] formatted duration string in the target unit
  # @example
  #   format_duration_from_seconds(7200, "hour") # => "2 hours"
  #   format_duration_from_seconds(90, "minute") # => "1.5 minutes"
  def format_duration_from_seconds(seconds, unit)
    seconds = seconds.to_i
    return "0 #{unit.to_s.pluralize}" if seconds <= 0

    case unit.to_s.downcase.chomp("s")
    when "day"
      value = seconds / (24 * 60 * 60.0)
    when "hour"
      value = seconds / (60 * 60.0)
    when "minute"
      value = seconds / 60.0
    when "second"
      value = seconds
    else
      value = seconds
    end

    rounded = value.round(2)
    label = (rounded == 1 ? unit.to_s.singularize : unit.to_s.pluralize)
    "#{rounded} #{label}"
  end
end
