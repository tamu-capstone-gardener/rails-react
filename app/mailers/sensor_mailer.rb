# app/mailers/sensor_mailer.rb
class SensorMailer < ApplicationMailer
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
  