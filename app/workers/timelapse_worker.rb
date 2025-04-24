# app/workers/timelapse_worker.rb
class TimelapseWorker
  include Sidekiq::Worker

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
