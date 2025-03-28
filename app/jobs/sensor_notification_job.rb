class SensorNotificationJob < ApplicationJob
    queue_as :default
  
    def perform(sensor_id, data_point_id)
      sensor = Sensor.find(sensor_id)
      Rails.logger.error("Sensor notifications flag: #{sensor.notifications}")
      data_point = TimeSeriesDatum.find(data_point_id)
  
      
        Rails.logger.error("Data point: #{data_point.inspect}")
        Rails.logger.error("Data point value: #{data_point.value.inspect}")

      
      # Only proceed if notifications are turned on
      return unless sensor.notifications
  
      sensor.thresholds.each_with_index do |threshold_condition, index|
        operator_match = threshold_condition.match(/(<=|>=|<|>)/)
        next unless operator_match
  
        operator = operator_match[0]            # "<=", ">=", "<", ">"
        threshold_value = threshold_condition.sub(operator, '').strip.to_f
  
        Rails.logger.error("Threshold value is #{threshold_value} for operator #{operator}")
  
        triggered = case operator
                when "<=" then data_point.value <= threshold_value
                when "<"  then data_point.value < threshold_value
                when ">"  then data_point.value > threshold_value
                when ">=" then data_point.value >= threshold_value
                else false
                end

  
        Rails.logger.error("Triggered? #{triggered} for data_point.value #{data_point.value}")
  
        if triggered
          message = sensor.messages[index] || "Notification triggered"
          PushNotificationService.send_notification(sensor.plant_module.user, message, sensor, data_point)

          SensorMailer.with(sensor: sensor, data_point: data_point, message: message)
                      .notification_email
                      .deliver_later
        end
      end
    end
  end
  