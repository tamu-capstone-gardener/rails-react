# app/services/timelapse_generator.rb

require "streamio-ffmpeg"
require "open-uri"
require "fileutils"

class TimelapseGenerator
  attr_reader :photos, :output_path, :frame_rate

  def initialize(photos:, output_path: "#{Rails.root}/tmp/timelapse.mp4", frame_rate: 10)
    @photos = if photos.respond_to?(:order)
      photos.order(:timestamp)
    else
      Array(photos).sort_by(&:timestamp)
    end
    @output_path = output_path
    @frame_rate = frame_rate
  end

  def generate
    Dir.mktmpdir do |dir|
      image_paths = download_images(dir)
      return nil if image_paths.empty?

      image_list_file = create_ffmpeg_image_list(dir, image_paths)
      build_timelapse_video(image_list_file)

      output_path
    end
  end

  private

  def download_images(dir)
    photos.each_with_index.map do |photo, i|
      # build a frame file name based on the blob’s original extension:
      ext      = File.extname(photo.image.filename.to_s)
      filename = format("frame_%05d#{ext}", i)
      dest     = File.join(dir, filename)

      # open the attached blob and copy it into your tmp dir:
      photo.image.blob.open do |tempfile|
        FileUtils.cp(tempfile.path, dest)
      end

      dest
    rescue => e
      Rails.logger.error "[TimelapseGenerator] download failed: #{e.message}"
      nil
    end.compact
  end

  def create_ffmpeg_image_list(dir, image_paths)
    list_file = File.join(dir, "images.txt")

    File.open(list_file, "w") do |f|
      image_paths.each do |path|
        f.puts("file '#{path}'")
      end
    end

    list_file
  end

  def build_timelapse_video(list_file)
    ffmpeg_command = [
      "ffmpeg",
      "-y",
      "-f", "concat",
      "-safe", "0",
      "-i", list_file,
      "-r", frame_rate.to_s,
      "-c:v", "libx264",
      "-pix_fmt", "yuv420p",
      output_path
    ].join(" ")

    system(ffmpeg_command)
  end
end
