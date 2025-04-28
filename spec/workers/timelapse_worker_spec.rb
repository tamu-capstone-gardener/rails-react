require 'rails_helper'

RSpec.describe TimelapseWorker, type: :worker do
  describe '#perform' do
    let(:plant_module) { create(:plant_module) }
    let(:photos) { build_list(:photo, 3, plant_module: plant_module) }
    let(:timelapse_generator) { double('TimelapseGenerator') }
    let(:output_path) { "#{Rails.root}/tmp/test_timelapse.mp4" }

    before do
      allow(PlantModule).to receive(:find).with(plant_module.id).and_return(plant_module)
      # Setup the TimelapseGenerator class double to mimic the class method new
      allow(TimelapseGenerator).to receive(:new).and_return(timelapse_generator)
      allow(Rails.logger).to receive(:error)
    end

    context 'when photos are available' do
      before do
        allow(plant_module).to receive_message_chain(:photos, :order).and_return(photos)
        allow(photos).to receive(:to_a).and_return(photos)

        # Mock each photo to have an attached image
        photos.each do |photo|
          allow(photo).to receive(:image).and_return(double('attachment', attached?: true))
        end
      end

      it 'generates a timelapse and attaches it to the plant module' do
        # Mock the file operations
        file_double = double('File')

        allow(timelapse_generator).to receive(:generate).and_return(output_path)
        allow(File).to receive(:exist?).with(output_path).and_return(true)
        allow(File).to receive(:open).with(output_path).and_return(file_double)
        allow(plant_module).to receive_message_chain(:timelapse_video, :attach)

        subject.perform(plant_module.id)

        expect(TimelapseGenerator).to have_received(:new).with(photos: photos)
        expect(timelapse_generator).to have_received(:generate)
        expect(plant_module.timelapse_video).to have_received(:attach).with(
          io: file_double,
          filename: "timelapse_#{plant_module.id}.mp4",
          content_type: "video/mp4"
        )
      end
    end

    context 'when no photos are available' do
      it 'returns early when no photos are found' do
        empty_array = []
        allow(plant_module).to receive_message_chain(:photos, :order).and_return(empty_array)
        allow(empty_array).to receive(:to_a).and_return(empty_array)

        expect(TimelapseGenerator).not_to receive(:new)

        subject.perform(plant_module.id)
      end

      it 'returns early when photos have no attached images' do
        photos_without_images = build_list(:photo, 3, plant_module: plant_module)

        # Mock photos with no attached images
        photos_without_images.each do |photo|
          allow(photo).to receive(:image).and_return(double('attachment', attached?: false))
        end

        allow(plant_module).to receive_message_chain(:photos, :order).and_return(photos_without_images)
        allow(photos_without_images).to receive(:to_a).and_return(photos_without_images)

        expect(TimelapseGenerator).not_to receive(:new)

        subject.perform(plant_module.id)
      end
    end

    context 'when timelapse generation fails' do
      before do
        allow(plant_module).to receive_message_chain(:photos, :order).and_return(photos)
        allow(photos).to receive(:to_a).and_return(photos)

        # Mock each photo to have an attached image
        photos.each do |photo|
          allow(photo).to receive(:image).and_return(double('attachment', attached?: true))
        end
      end

      it 'returns early when generator returns nil' do
        allow(timelapse_generator).to receive(:generate).and_return(nil)

        expect(plant_module).not_to receive(:timelapse_video)

        subject.perform(plant_module.id)
      end

      it 'returns early when output file does not exist' do
        allow(timelapse_generator).to receive(:generate).and_return(output_path)
        allow(File).to receive(:exist?).with(output_path).and_return(false)

        expect(plant_module).not_to receive(:timelapse_video)

        subject.perform(plant_module.id)
      end

      it 'handles exceptions gracefully' do
        allow(timelapse_generator).to receive(:generate).and_raise(StandardError.new('Test error'))

        expect(Rails.logger).to receive(:error).with('[TimelapseWorker] StandardError: Test error')
        expect { subject.perform(plant_module.id) }.not_to raise_error
      end
    end

    context 'when plant module is not found' do
      it 'handles the error gracefully' do
        allow(PlantModule).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

        expect(Rails.logger).to receive(:error).with(/\[TimelapseWorker\] ActiveRecord::RecordNotFound/)
        expect { subject.perform(999) }.not_to raise_error
      end
    end
  end
end
