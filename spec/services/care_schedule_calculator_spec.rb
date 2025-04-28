require 'rails_helper'

RSpec.describe CareScheduleCalculator do
  # Create simple plant doubles with needed attributes
  let(:fast_plant) { double("Plant", growth_rate: "fast", plant_type: "succulent", soils: '["dry"]') }
  let(:moderate_plant) { double("Plant", growth_rate: "moderate", plant_type: "flowering", soils: '["medium"]') }
  let(:slow_plant) { double("Plant", growth_rate: "slow", plant_type: "deciduous", soils: '["moist"]') }
  let(:nil_plant) { double("Plant", growth_rate: nil, plant_type: nil, soils: nil) }

  describe "#calculate" do
    context "with plants" do
      let(:calculator) { described_class.new([ fast_plant, moderate_plant, slow_plant ]) }

      it "returns a complete care schedule" do
        result = calculator.calculate

        expect(result).to include(
          watering_frequency: 2,
          fertilizer_frequency: 45,
          light_hours: 7,
          soil_moisture_pref: "dry"
        )
      end

      it "uses most frequent soil type as preference" do
        plants = [
          double("Plant", growth_rate: "moderate", plant_type: "fern", soils: '["medium", "moist"]'),
          double("Plant", growth_rate: "moderate", plant_type: "fern", soils: '["medium", "dry"]'),
          double("Plant", growth_rate: "moderate", plant_type: "fern", soils: '["medium", "wet"]')
        ]

        result = described_class.new(plants).calculate
        expect(result[:soil_moisture_pref]).to eq("medium")
      end
    end

    context "with no plants" do
      let(:calculator) { described_class.new([]) }

      it "returns default values" do
        result = calculator.calculate

        expect(result).to eq(
          watering_frequency: 7,
          fertilizer_frequency: 30,
          light_hours: 8,
          soil_moisture_pref: "medium"
        )
      end
    end

    context "with nil attributes" do
      let(:calculator) { described_class.new([ nil_plant ]) }

      it "handles nil values gracefully" do
        result = calculator.calculate

        expect(result).to include(
          watering_frequency: 7,
          fertilizer_frequency: 30
        )
      end
    end
  end

  describe "watering frequency" do
    it "recommends shortest frequency based on growth rate" do
      calculator = described_class.new([ moderate_plant, slow_plant ])
      expect(calculator.send(:recommended_watering_frequency)).to eq(4)

      calculator = described_class.new([ fast_plant, moderate_plant, slow_plant ])
      expect(calculator.send(:recommended_watering_frequency)).to eq(2)
    end
  end

  describe "fertilizer frequency" do
    it "recommends longest frequency based on growth rate" do
      calculator = described_class.new([ fast_plant, moderate_plant ])
      expect(calculator.send(:recommended_fertilizer_frequency)).to eq(30)

      calculator = described_class.new([ fast_plant, moderate_plant, slow_plant ])
      expect(calculator.send(:recommended_fertilizer_frequency)).to eq(45)
    end
  end

  describe "light hours" do
    it "calculates average light hours based on plant type" do
      calculator = described_class.new([
        double("Plant", growth_rate: "moderate", plant_type: "deciduous", soils: "[]"),
        double("Plant", growth_rate: "moderate", plant_type: "flowering", soils: "[]")
      ])

      expect(calculator.send(:recommended_light_hours)).to eq(7)
    end
  end

  describe "soil moisture preference" do
    it "handles invalid JSON gracefully" do
      plant = double("Plant", growth_rate: "moderate", plant_type: "fern", soils: "invalid json")
      calculator = described_class.new([ plant ])

      expect(calculator.send(:recommended_soil_moisture_pref)).to eq("medium")
    end

    it "handles empty arrays" do
      plant = double("Plant", growth_rate: "moderate", plant_type: "fern", soils: "[]")
      calculator = described_class.new([ plant ])

      expect(calculator.send(:recommended_soil_moisture_pref)).to eq("medium")
    end
  end

  describe "parse_soils" do
    it "parses valid JSON arrays" do
      calculator = described_class.new([])
      expect(calculator.send(:parse_soils, '["dry", "medium"]')).to eq([ "dry", "medium" ])
    end

    it "returns empty array for invalid JSON" do
      calculator = described_class.new([])
      expect(calculator.send(:parse_soils, 'not json')).to eq([])
    end

    it "returns empty array for nil input" do
      calculator = described_class.new([])
      expect(calculator.send(:parse_soils, nil)).to eq([])
    end

    it "returns empty array when JSON is not an array" do
      calculator = described_class.new([])
      expect(calculator.send(:parse_soils, '{"soil": "dry"}')).to eq([])
    end
  end
end
