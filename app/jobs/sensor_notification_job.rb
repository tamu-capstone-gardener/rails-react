# Background job for processing sensor notification thresholds and sending alerts
#
# This job checks if a sensor reading has crossed configured thresholds
# and sends notification emails when conditions are met.
class SensorNotificationJob < ApplicationJob
  queue_as :default

  # Processes notifications for a sensor data point
  #
  # @param sensor_id [String] UUID of the sensor to check
  # @param data_point_id [Integer] ID of the time series data point to evaluate
  # @return [void]
  # @note Notifications are only sent if the sensor has notifications enabled
  #   and the threshold hasn't triggered a notification in the last 6 hours
  def perform(sensor_id, data_point_id)
    sensor = Sensor.find(sensor_id)
    data_point = TimeSeriesDatum.find(data_point_id)

    Rails.logger.info "Processing notifications for sensor #{sensor.id} with data point #{data_point.id}"
    Rails.logger.info "Sensor notifications flag: #{sensor.notifications}"
    Rails.logger.info "Data point value: #{data_point.value}"

    return unless sensor.notifications

    # Ensure notified_threshold_indices is initialized
    data_point.notified_threshold_indices ||= ""

    sensor.thresholds.each_with_index do |threshold_condition, index|
      # Extract the operator and threshold number
      if threshold_condition =~ /\A\s*(<=|>=|<|>|=)\s*(-?\d+(\.\d+)?)\s*\z/
        operator = Regexp.last_match(1)
        threshold_value = Regexp.last_match(2).to_f

        Rails.logger.info "Checking threshold #{index + 1}: #{operator} #{threshold_value}"

        triggered = case operator
        when "<=" then data_point.value <= threshold_value
        when "<"  then data_point.value < threshold_value
        when "="  then data_point.value == threshold_value
        when ">=" then data_point.value >= threshold_value
        when ">"  then data_point.value > threshold_value
        else false
        end

        Rails.logger.info "Threshold triggered? #{triggered}"

        # Skip if already notified for this threshold index
        already_notified = data_point.notified_threshold_indices.to_s.include?(index.to_s)

        log = SensorNotificationLog.find_or_initialize_by(sensor: sensor, threshold_index: index)

        if triggered && !already_notified && (log.last_sent_at.nil? || log.last_sent_at <= 6.hours.ago)
          message = sensor.messages[index] || "Notification triggered"

          Rails.logger.info "Sending notification: #{message}"

          SensorMailer.with(sensor: sensor, data_point: data_point, message: message)
                      .notification_email
                      .deliver_later

          # Mark this threshold as notified
          data_point.notified_threshold_indices = [ *data_point.notified_threshold_indices.to_s.split(","), index.to_s ].uniq.join(",")
          data_point.save!

          log.last_sent_at = Time.current
          log.save!
        else
          Rails.logger.info "Skipping notification for threshold #{index} due to 6-hour cooldown or prior notification."
        end

      else
        Rails.logger.warn "Malformed threshold: '#{threshold_condition}' – skipping"
      end
    end
  rescue => e
    Rails.logger.error "Error processing notifications: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
