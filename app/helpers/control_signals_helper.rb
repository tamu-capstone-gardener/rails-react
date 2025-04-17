module ControlSignalsHelper
  # format_duration(amount, unit) → "3 hours", "1 minute", etc.
  def format_duration(amount, unit)
    amount = amount.to_i
    # nothing or zero → “0 seconds”
    return "0 #{unit.to_s.pluralize}" if amount <= 0

    # normalize to singular base (e.g. "hours" → "hour")
    base = unit.to_s.downcase.chomp("s")
    label = (amount == 1 ? base : base.pluralize)
    "#{amount} #{label}"
  end

  # format_duration_to_seconds(amount, unit) → integer seconds
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

  # format_duration_from_seconds(7200, "hours") → "2 hours"
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
