class PushNotificationService
  def self.send_notification(user, message, sensor, data_point)
    return unless user.present? && message.present? && sensor.present? && data_point.present?

    payload = {
      title: "Sensor Alert: #{sensor.measurement_type}",
      message: message,
      value: data_point.value,
      unit: sensor.measurement_unit,
      timestamp: data_point.timestamp
    }

    Rails.logger.info "Sending push notification to #{user.email}: #{payload.inspect}"

    begin
      ::NotificationsChannel.broadcast_to(user, payload)
      Rails.logger.info "Successfully sent push notification to #{user.email}"
    rescue => e
      Rails.logger.error "Failed to send push notification to #{user.email}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
