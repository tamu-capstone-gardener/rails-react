# Preview all emails at http://localhost:3000/rails/mailers/sensor_mailer
class SensorMailerPreview < ActionMailer::Preview
  def notification_email
    sensor = Sensor.first || FactoryBot.create(:sensor, measurement_type: 'temperature')
    data_point = TimeSeriesData.where(sensor_id: sensor.id).first ||
                 FactoryBot.create(:time_series_datum, sensor: sensor, value: 25.0)

    SensorMailer.with(
      sensor: sensor,
      data_point: data_point,
      message: 'This is a preview of the sensor notification email'
    ).notification_email
  end
end
