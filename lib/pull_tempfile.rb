require 'httparty'     # gem
require 'pathname'     # standard Ruby lib
require 'tempfile'     # standard Ruby lib

require "pull_tempfile/version"

module PullTempfile
  # Creates Temporary file
  #
  #     file = PullTempfile.pull_tempfile(original_filename: "image asset.jpg", url: 'http://..../uaoeuoeueoauoueao' )
  #     # ...do stuff
  #     file.unlink
  #
  # Temporary files have suffix so your file "image asset.jpg"
  # will be saved as "/tmp/image asset20160317-18066-gw1q0.jpg". This is because
  # Tempfile lib is ensuring you won't override files
  #
  # Remmember to `file.unlink` or PullTempfile.transaction that does that automatically
  #
  def self.pull_tempfile(original_filename:, url:)
    _generated_name = Pathname.new(original_filename)
    extension     = _generated_name.extname.to_s
    tmp_file_name = _generated_name.basename(extension).to_s

    file = Tempfile.new([tmp_file_name, extension])
    file.binmode
    file.write(HTTParty.get(url).parsed_response)
    file.close
    file
  end

  def self.transaction(original_filename:, url:)
    file = pull_tempfile(original_filename: original_filename, url: url)

    yield file.open
  ensure
    file && file.unlink #delete temp file
  end
end
