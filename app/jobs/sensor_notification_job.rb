class SensorNotificationJob < ApplicationJob
    queue_as :default

    def perform(sensor_id, data_point_id)
      begin
        sensor = Sensor.find(sensor_id)
        data_point = TimeSeriesDatum.find(data_point_id)

        Rails.logger.info "Processing notifications for sensor #{sensor.id} with data point #{data_point.id}"
        Rails.logger.info "Sensor notifications flag: #{sensor.notifications}"
        Rails.logger.info "Data point value: #{data_point.value}"

        # Only proceed if notifications are turned on
        unless sensor.notifications
          Rails.logger.info "Notifications are disabled for sensor #{sensor.id}"
          return
        end

        sensor.thresholds.each_with_index do |threshold_condition, index|
          operator_match = threshold_condition.match(/(<=|>=|<|>)/)
          next unless operator_match

          operator = operator_match[0]            # "<=", ">=", "<", ">"
          threshold_value = threshold_condition.sub(operator, "").strip.to_f

          Rails.logger.info "Checking threshold #{index + 1}: #{threshold_condition}"

          triggered = case operator
          when "<=" then data_point.value <= threshold_value
          when "<"  then data_point.value < threshold_value
          when ">"  then data_point.value > threshold_value
          when ">=" then data_point.value >= threshold_value
          else false
          end

          Rails.logger.info "Threshold triggered? #{triggered} for data_point.value #{data_point.value}"

          if triggered && !data_point.notified_threshold_indices.include?(index)
            message = sensor.messages[index] || "Notification triggered"

            Rails.logger.info "Sending notification with message: #{message}"
            PushNotificationService.send_notification(sensor.plant_module.user, message, sensor, data_point)

            SensorMailer.with(sensor: sensor, data_point: data_point, message: message)
                        .notification_email
                        .deliver_later

            # Mark this threshold as notified
            data_point.notified_threshold_indices << index
            data_point.save!
          end
        end
      rescue => e
        Rails.logger.error "Error processing notifications: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end
    end
end
