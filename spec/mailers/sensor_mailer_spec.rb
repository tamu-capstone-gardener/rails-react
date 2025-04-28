require 'rails_helper'

RSpec.describe SensorMailer, type: :mailer do
  describe '#notification_email' do
    let(:user) { create(:user, email: 'test@example.com') }
    let(:plant_module) { create(:plant_module, user: user) }
    let(:sensor) { create(:sensor, plant_module: plant_module, measurement_type: 'temperature') }
    let(:data_point) { create(:time_series_datum, sensor: sensor, value: 25.0) }
    let(:message) { 'Temperature is above threshold!' }

    let(:mail) do
      SensorMailer.with(
        sensor: sensor,
        data_point: data_point,
        message: message
      ).notification_email
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Sensor Alert: temperature')
      expect(mail.to).to eq([ 'test@example.com' ])
      expect(mail.from).not_to be_empty
    end

    it 'renders the body with sensor information' do
      expect(mail.body.encoded).to match(message)
    end

    it 'logs information about the email being sent' do
      allow(Rails.logger).to receive(:info)
      mail.deliver_now
      expect(Rails.logger).to have_received(:info).with("Trying to send an email to test@example.com")
    end
  end
end
