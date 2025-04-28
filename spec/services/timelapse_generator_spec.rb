require 'rails_helper'

RSpec.describe TimelapseGenerator do
  # Use simple doubles without worrying about specific class types
  let(:image) { double("image", filename: double(to_s: "test.jpg"), blob: double) }

  # Create photo doubles with only what's needed
  let(:photo1) { double("photo", timestamp: 1.hour.ago, image: image) }
  let(:photo2) { double("photo", timestamp: 2.hours.ago, image: image) }

  let(:photos) { [ photo1, photo2 ] }
  let(:tmp_dir) { "/tmp/fake_dir" }
  let(:output_path) { "#{Rails.root}/tmp/test_timelapse.mp4" }
  let(:frame_rate) { 15 }

  subject { described_class.new(photos: photos, output_path: output_path, frame_rate: frame_rate) }

  before do
    # Set up our stubs as simply as possible
    allow(Dir).to receive(:mktmpdir).and_yield(tmp_dir)
    allow(FileUtils).to receive(:cp)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(anything, "w").and_yield(double(puts: nil))

    # Fix the tempfile double to include a path method
    tempfile = double("tempfile", path: "/tmp/mock_tempfile.jpg")
    allow(image.blob).to receive(:open).and_yield(tempfile)

    allow_any_instance_of(described_class).to receive(:system).and_return(true)
  end

  describe "#initialize" do
    it "initializes with sorted photos" do
      generator = described_class.new(photos: photos)
      expect(generator.photos.first.timestamp).to be < generator.photos.last.timestamp
    end

    context "with an ActiveRecord relation" do
      it "calls order on the relation" do
        relation = double("relation")
        allow(relation).to receive(:respond_to?).with(:order).and_return(true)
        allow(relation).to receive(:order).with(:timestamp).and_return([ photo2, photo1 ])

        generator = described_class.new(photos: relation)
        expect(generator.photos).to eq([ photo2, photo1 ])
      end
    end
  end

  describe "#generate" do
    it "generates a timelapse video" do
      result = subject.generate
      expect(result).to eq(output_path)
    end

    it "handles empty image sets" do
      allow(subject).to receive(:download_images).and_return([])
      expect(subject.generate).to be_nil
    end
  end

  describe "private methods" do
    it "downloads images" do
      result = subject.send(:download_images, tmp_dir)
      expect(result).to be_an(Array)
    end

    it "creates an ffmpeg image list" do
      result = subject.send(:create_ffmpeg_image_list, tmp_dir, [ "image1.jpg", "image2.jpg" ])
      expect(result).to include(tmp_dir)
    end

    it "builds a timelapse video" do
      expect(subject.send(:build_timelapse_video, "list.txt")).to eq(true)
    end
  end
end
