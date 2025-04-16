module ControlSignalsHelper
  def format_duration(ms)
    return "0 ms" unless ms && ms > 0

    units = {
      "day" => 86_400_000,
      "hour" => 3_600_000,
      "minute" => 60_000,
      "second" => 1_000
    }

    units.each do |name, value|
      if ms >= value
        amount = ms / value
        return "#{amount} #{name}#{'s' if amount != 1}"
      end
    end

    "#{ms} ms"
  end
end
