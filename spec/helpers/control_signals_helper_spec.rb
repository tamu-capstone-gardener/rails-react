require 'rails_helper'

RSpec.describe ControlSignalsHelper, type: :helper do
  describe '#format_duration' do
    it 'formats a singular unit correctly' do
      expect(helper.format_duration(1, 'day')).to eq('1 day')
      expect(helper.format_duration(1, 'hour')).to eq('1 hour')
      expect(helper.format_duration(1, 'minute')).to eq('1 minute')
      expect(helper.format_duration(1, 'second')).to eq('1 second')
    end

    it 'formats a plural unit correctly' do
      expect(helper.format_duration(2, 'day')).to eq('2 days')
      expect(helper.format_duration(5, 'hour')).to eq('5 hours')
      expect(helper.format_duration(10, 'minute')).to eq('10 minutes')
      expect(helper.format_duration(30, 'second')).to eq('30 seconds')
    end

    it 'handles units already in plural form' do
      expect(helper.format_duration(2, 'days')).to eq('2 days')
      expect(helper.format_duration(5, 'hours')).to eq('5 hours')
    end

    it 'handles zero value' do
      expect(helper.format_duration(0, 'day')).to eq('0 days')
    end

    it 'handles negative value' do
      expect(helper.format_duration(-1, 'day')).to eq('0 days')
    end

    it 'handles string input for amount' do
      expect(helper.format_duration('3', 'hour')).to eq('3 hours')
    end
  end

  describe '#format_duration_to_seconds' do
    it 'converts days to seconds correctly' do
      expect(helper.format_duration_to_seconds(1, 'day')).to eq(86400) # 24*60*60
      expect(helper.format_duration_to_seconds(2, 'days')).to eq(172800) # 2*24*60*60
    end

    it 'converts hours to seconds correctly' do
      expect(helper.format_duration_to_seconds(1, 'hour')).to eq(3600) # 60*60
      expect(helper.format_duration_to_seconds(2, 'hours')).to eq(7200) # 2*60*60
    end

    it 'converts minutes to seconds correctly' do
      expect(helper.format_duration_to_seconds(1, 'minute')).to eq(60)
      expect(helper.format_duration_to_seconds(2, 'minutes')).to eq(120) # 2*60
    end

    it 'returns seconds as is' do
      expect(helper.format_duration_to_seconds(30, 'second')).to eq(30)
      expect(helper.format_duration_to_seconds(45, 'seconds')).to eq(45)
    end

    it 'handles zero value' do
      expect(helper.format_duration_to_seconds(0, 'day')).to eq(0)
    end

    it 'handles negative value' do
      expect(helper.format_duration_to_seconds(-5, 'hour')).to eq(0)
    end

    it 'handles string input for amount' do
      expect(helper.format_duration_to_seconds('3', 'hour')).to eq(10800) # 3*60*60
    end

    it 'handles unknown units' do
      expect(helper.format_duration_to_seconds(3, 'unknown')).to eq(3)
    end
  end

  describe '#format_duration_from_seconds' do
    it 'converts seconds to days correctly' do
      expect(helper.format_duration_from_seconds(86400, 'day')).to eq('1.0 day')
      expect(helper.format_duration_from_seconds(172800, 'day')).to eq('2.0 days')
      expect(helper.format_duration_from_seconds(129600, 'day')).to eq('1.5 days')
    end

    it 'converts seconds to hours correctly' do
      expect(helper.format_duration_from_seconds(3600, 'hour')).to eq('1.0 hour')
      expect(helper.format_duration_from_seconds(7200, 'hour')).to eq('2.0 hours')
      expect(helper.format_duration_from_seconds(5400, 'hour')).to eq('1.5 hours')
    end

    it 'converts seconds to minutes correctly' do
      expect(helper.format_duration_from_seconds(60, 'minute')).to eq('1.0 minute')
      expect(helper.format_duration_from_seconds(120, 'minute')).to eq('2.0 minutes')
      expect(helper.format_duration_from_seconds(90, 'minute')).to eq('1.5 minutes')
    end

    it 'returns seconds as is' do
      expect(helper.format_duration_from_seconds(30, 'second')).to eq('30 seconds')
      expect(helper.format_duration_from_seconds(1, 'second')).to eq('1 second')
    end

    it 'handles zero value' do
      expect(helper.format_duration_from_seconds(0, 'day')).to eq('0 days')
    end

    it 'handles negative value' do
      expect(helper.format_duration_from_seconds(-60, 'minute')).to eq('0 minutes')
    end

    it 'handles fractional values with proper rounding' do
      expect(helper.format_duration_from_seconds(3661, 'hour')).to eq('1.02 hours')
      expect(helper.format_duration_from_seconds(90.7, 'minute')).to eq('1.5 minutes')
    end

    it 'handles unknown units' do
      expect(helper.format_duration_from_seconds(123, 'unknown')).to eq('123 unknowns')
    end

    it 'handles pluralized unit parameter' do
      expect(helper.format_duration_from_seconds(7200, 'hours')).to eq('2.0 hours')
    end
  end
end
