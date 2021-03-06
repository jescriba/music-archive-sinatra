require_relative '../globals'
require 'aws-sdk'
require 'fileutils'

class SongTranscoder
  include Globals
  @queue = :song_transcode

  # UploadParams: file_params.merge({ :artist_name => artist_name,
  #                                     :song_name => song_name,
  #                                     :base_url => base_url,
  #                                     :lossy_url => lossy_url,
  #                                     :lossless_url => lossless_url,
  #                                     :is_lossless => lossless_url.empty?,
  #                                  })
  def self.perform(upload_params)
    s3 = Aws::S3::Resource.new(region: 'us-west-1')

    # Ensure we are working w/ symbols
    upload_params = upload_params.reduce({}) { |memo, (k, v)| memo.merge({ k.to_sym => v}) }
    extension = File.extname(upload_params[:lossless_url])
    # Download s3 lossless to local
    upload_params[:tempfile_path] = "/app/tmp/temp#{extension}"
    download_cmd_str = "curl -o #{upload_params[:tempfile_path]} #{upload_params[:lossless_url]}"
    download_cmd =  `#{download_cmd_str}`
    tempfile = File.new(upload_params[:tempfile_path], "r")

    # transcode to V0 mp3
    temp_fi_dirname = File.dirname(upload_params[:tempfile_path])
    lossy_file_path = "#{temp_fi_dirname}/#{upload_params[:song_name]}.mp3"
    cmd = "ffmpeg -i #{upload_params[:tempfile_path]} -codec:a libmp3lame -qscale:a 0 #{lossy_file_path}"
    `#{cmd}`
    lossy_file = File.new(lossy_file_path, "r")

    # upload lossy
    lossy_object_path = upload_params[:lossy_url].sub(upload_params[:base_url], "")
    s3_lossy_object = s3.bucket(BUCKET).object(lossy_object_path)

    # upload
    s3_lossy_object.upload_file(lossy_file, acl: 'public-read')
    s3_lossy_object.copy_to("#{s3_lossy_object.bucket.name}/#{s3_lossy_object.key}",
                            :metadata_directive => "REPLACE",
                            :acl => "public-read",
                            :content_type => "audio/mpeg",
                            :content_disposition => "attachment; filename='#{upload_params[:song_name]}.mp3'")

    # Clean up lossy temp file
    FileUtils.rm(lossy_file_path)

    # Clean up - delete temp file
    FileUtils.rm([upload_params[:tempfile_path]])
  end
end
