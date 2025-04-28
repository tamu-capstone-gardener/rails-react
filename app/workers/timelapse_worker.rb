# app/workers/timelapse_worker.rb

# Background worker for generating timelapse videos
#
# This worker processes plant module photos asynchronously to create
# timelapse videos showing plant growth over time.
class TimelapseWorker
  include Sidekiq::Worker

  # Generates a timelapse video for a plant module from its photos
  #
  # @param plant_module_id [String] UUID of the plant module to generate timelapse for
  # @return [void]
  # @note The generated timelapse video is attached to the plant module
  #   as an ActiveStorage attachment named timelapse_video
  def perform(plant_module_id)
    pm = PlantModule.find(plant_module_id)

    ordered_photos = pm.photos.order(created_at: :asc)

    photos = ordered_photos.to_a.select { |p| p.image.attached? }
    return if photos.empty?

    output = TimelapseGenerator.new(photos: photos).generate
    return unless output && File.exist?(output)

    if output && File.exist?(output)
      pm.timelapse_video.attach(
        io: File.open(output),
        filename: "timelapse_#{pm.id}.mp4",
        content_type: "video/mp4"
      )
    end
  rescue => e
    Rails.logger.error "[TimelapseWorker] #{e.class}: #{e.message}"
  end
end
