# app/services/timelapse_generator.rb

require "streamio-ffmpeg"
require "open-uri"
require "fileutils"

# Service for generating timelapse videos from a collection of photos
#
# This service uses FFmpeg to combine a sequence of images into a timelapse
# video, which can be used to visualize plant growth over time.
class TimelapseGenerator
  # @return [Array<Photo>] the photos to include in the timelapse
  attr_reader :photos

  # @return [String] path where the output video will be saved
  attr_reader :output_path

  # @return [Integer] frames per second in the output video
  attr_reader :frame_rate

  # Initializes a new timelapse generator
  #
  # @param photos [Array<Photo>, ActiveRecord::Relation] photos to include in the timelapse
  # @param output_path [String] path where the output video will be saved
  # @param frame_rate [Integer] frames per second in the output video
  # @return [TimelapseGenerator] a new instance ready to generate a timelapse
  def initialize(photos:, output_path: "#{Rails.root}/tmp/timelapse.mp4", frame_rate: 10)
    @photos = if photos.respond_to?(:order)
      photos.order(:timestamp)
    else
      Array(photos).sort_by(&:timestamp)
    end
    @output_path = output_path
    @frame_rate = frame_rate
  end

  # Generates the timelapse video
  #
  # @return [String, nil] path to the generated video, or nil if generation failed
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

  # Downloads attached images to a temporary directory
  #
  # @param dir [String] temporary directory path
  # @return [Array<String>] array of paths to downloaded images
  def download_images(dir)
    photos.each_with_index.map do |photo, i|
      # build a frame file name based on the blob's original extension:
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

  # Creates an FFmpeg-compatible list file of image paths
  #
  # @param dir [String] directory path where the list file will be created
  # @param image_paths [Array<String>] paths to the downloaded images
  # @return [String] path to the created list file
  def create_ffmpeg_image_list(dir, image_paths)
    list_file = File.join(dir, "images.txt")

    File.open(list_file, "w") do |f|
      image_paths.each do |path|
        f.puts("file '#{path}'")
      end
    end

    list_file
  end

  # Builds the timelapse video using FFmpeg
  #
  # @param list_file [String] path to the FFmpeg image list file
  # @return [Boolean] true if the video was successfully created
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
