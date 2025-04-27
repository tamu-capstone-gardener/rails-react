require 'rails_helper'

RSpec.describe SensorNotificationJob, type: :job do
  describe '#perform' do
    # Use let! to eagerly evaluate these before each test
    let!(:sensor) { create(:sensor) }
    let!(:data_point) { build_stubbed(:time_series_datum, value: 25, sensor: sensor) }

    before do
      # Stub the check_sensor_notifications callback to prevent side effects
      allow_any_instance_of(TimeSeriesDatum).to receive(:check_sensor_notifications)

      # Set up stubs for direct find calls
      allow(Sensor).to receive(:find).with(sensor.id).and_return(sensor)
      allow(TimeSeriesDatum).to receive(:find).with(data_point.id).and_return(data_point)
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
    end

    context 'when notifications are disabled' do
      before do
        allow(sensor).to receive(:notifications).and_return(false)
      end

      it 'does not process thresholds' do
        expect(sensor).not_to receive(:thresholds)

        described_class.perform_now(sensor.id, data_point.id)
      end
    end

    context 'when notifications are enabled' do
      before do
        allow(sensor).to receive(:notifications).and_return(true)
        allow(sensor).to receive(:thresholds).and_return([ '> 20', '< 10' ])
        allow(sensor).to receive(:messages).and_return([ 'Too high', 'Too low' ])
        allow(data_point).to receive(:notified_threshold_indices).and_return('')
        allow(data_point).to receive(:notified_threshold_indices=)
        allow(data_point).to receive(:save!)
      end

      it 'processes each threshold condition' do
        notification_mailer = double('mailer')
        delivery_job = double('delivery_job')

        log = double('log', last_sent_at: nil, save!: true)
        allow(log).to receive(:last_sent_at=)
        allow(SensorNotificationLog).to receive(:find_or_initialize_by).and_return(log)

        # Setup mock for class method 'with' first
        mailer_class_double = class_double('SensorMailer')
        allow(SensorMailer).to receive(:with).and_return(notification_mailer)
        allow(notification_mailer).to receive(:notification_email).and_return(delivery_job)
        allow(delivery_job).to receive(:deliver_later)

        described_class.perform_now(sensor.id, data_point.id)

        # Should send notification for first threshold (> 20) since 25 > 20
        expect(SensorMailer).to have_received(:with).with(
          sensor: sensor,
          data_point: data_point,
          message: 'Too high'
        )
        expect(notification_mailer).to have_received(:notification_email)
        expect(delivery_job).to have_received(:deliver_later)
      end

      it 'handles various operators correctly' do
        operators = {
          '>=' => { value: 20, threshold: '>=20', expected: true },
          '>'  => { value: 20, threshold: '>19', expected: true },
          '='  => { value: 20, threshold: '=20', expected: true },
          '<'  => { value: 20, threshold: '<21', expected: true },
          '<=' => { value: 20, threshold: '<=20', expected: true }
        }

        operators.each do |operator, test_case|
          # Clean up all mocks and stubs between operator tests
          RSpec::Mocks.space.proxy_for(SensorMailer).reset

          data_point = instance_double('TimeSeriesDatum',
            id: 1,
            value: test_case[:value],
            notified_threshold_indices: '',
            save!: true
          )
          allow(data_point).to receive(:notified_threshold_indices=)
          allow(TimeSeriesDatum).to receive(:find).and_return(data_point)

          sensor = instance_double('Sensor',
            id: 1,
            notifications: true,
            thresholds: [ test_case[:threshold] ],
            messages: [ 'Threshold reached' ]
          )
          allow(Sensor).to receive(:find).and_return(sensor)

          log = instance_double('SensorNotificationLog', last_sent_at: nil, save!: true)
          allow(log).to receive(:last_sent_at=)
          allow(SensorNotificationLog).to receive(:find_or_initialize_by).and_return(log)

          mailer = double('mailer')
          delivery = double('delivery')
          allow(SensorMailer).to receive(:with).and_return(mailer)
          allow(mailer).to receive(:notification_email).and_return(delivery)
          allow(delivery).to receive(:deliver_later)

          described_class.perform_now(1, 1)

          # Each operator should result in exactly one notification
          expect(SensorMailer).to have_received(:with).exactly(1).time
        end
      end

      # Additional test cases to check negative scenarios
      it 'skips notifications for non-matching operator conditions' do
        operators = {
          '>'  => { value: 20, threshold: '>20', expected: false },
          '<'  => { value: 20, threshold: '<20', expected: false }
        }

        operators.each do |operator, test_case|
          data_point = instance_double('TimeSeriesDatum',
            id: 1,
            value: test_case[:value],
            notified_threshold_indices: '',
            save!: true
          )
          allow(data_point).to receive(:notified_threshold_indices=)
          allow(TimeSeriesDatum).to receive(:find).and_return(data_point)

          sensor = instance_double('Sensor',
            id: 1,
            notifications: true,
            thresholds: [ test_case[:threshold] ],
            messages: [ 'Threshold reached' ]
          )
          allow(Sensor).to receive(:find).and_return(sensor)

          log = instance_double('SensorNotificationLog', last_sent_at: nil, save!: true)
          allow(SensorNotificationLog).to receive(:find_or_initialize_by).and_return(log)

          # We expect the mailer not to be called in these cases
          expect(SensorMailer).not_to receive(:with)

          described_class.perform_now(1, 1)
        end
      end

      it 'respects the 6-hour cooldown period' do
        notification_log = instance_double('SensorNotificationLog',
          last_sent_at: 7.hours.ago,
          save!: true
        )
        allow(notification_log).to receive(:last_sent_at=)
        allow(SensorNotificationLog).to receive(:find_or_initialize_by).and_return(notification_log)

        mailer = double('mailer')
        delivery = double('delivery')
        allow(SensorMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:notification_email).and_return(delivery)
        allow(delivery).to receive(:deliver_later)

        described_class.perform_now(sensor.id, data_point.id)
      end

      it 'does not send notifications during cooldown period' do
        notification_log = instance_double('SensorNotificationLog',
          last_sent_at: 5.hours.ago,
          save!: true
        )
        allow(SensorNotificationLog).to receive(:find_or_initialize_by).and_return(notification_log)

        expect(SensorMailer).not_to receive(:with)

        described_class.perform_now(sensor.id, data_point.id)
      end

      it 'does not send duplicate notifications for the same threshold' do
        allow(data_point).to receive(:notified_threshold_indices).and_return('0')

        expect(SensorMailer).not_to receive(:with)

        described_class.perform_now(sensor.id, data_point.id)
      end

      it 'logs warnings for malformed thresholds' do
        allow(sensor).to receive(:thresholds).and_return([ 'invalid threshold' ])

        expect(Rails.logger).to receive(:warn).with(/Malformed threshold/)

        described_class.perform_now(sensor.id, data_point.id)
      end
    end

    context 'when an error occurs' do
      before do
        allow(Sensor).to receive(:find).with(sensor.id).and_raise(StandardError.new('Test error'))
      end

      it 'logs the error and re-raises it' do
        expect(Rails.logger).to receive(:error).with(/Error processing notifications: Test error/)
        expect(Rails.logger).to receive(:error) # For backtrace

        expect {
          described_class.perform_now(sensor.id, data_point.id)
        }.to raise_error(StandardError, 'Test error')
      end
    end
  end
end
