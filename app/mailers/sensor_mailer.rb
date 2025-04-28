# app/mailers/sensor_mailer.rb

# Mailer for sending sensor-related notifications and alerts
#
# This mailer handles sending email notifications when sensors
# detect values crossing configured thresholds.
class SensorMailer < ApplicationMailer
    # Sends a notification email about a sensor reading that crossed a threshold
    #
    # @param params [Hash] parameters for the email
    # @option params [Sensor] :sensor the sensor that triggered the notification
    # @option params [TimeSeriesDatum] :data_point the data point that triggered the notification
    # @option params [String] :message custom message to include in the notification
    # @return [Mail::Message] email message to be delivered
    def notification_email
      @sensor     = params[:sensor]
      @data_point = params[:data_point]
      @message    = params[:message]

      Rails.logger.info("Trying to send an email to #{@sensor.plant_module.user.email}")

      mail(
        to: @sensor.plant_module.user.email,
        subject: "Sensor Alert: #{@sensor.measurement_type}"
      )
    end
end
