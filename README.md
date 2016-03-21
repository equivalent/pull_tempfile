# PullTempfile

[![Build Status](https://travis-ci.org/equivalent/pull_tempfile.svg?branch=master)](https://travis-ci.org/equivalent/pull_tempfile)
[![Code Climate](https://codeclimate.com/github/equivalent/pull_tempfile/badges/gpa.svg)](https://codeclimate.com/github/equivalent/pull_tempfile)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pull_tempfile'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pull_tempfile

## Usage

```
class Medium < ActiveRecord::Base
  has_attached_file :file

  # ...
end

require 'pull_tempfile'

# when used as "AWS S3 browser upload" you can fetch original filename as "${filename}" metadata
# or use some different way to determine the file name.
original_filename = 'no idea.png'

url = 'http://www.eq8.eu/no-idea.png'

medium = Media.new

PullTempfile.transaction(url: url, original_filename: original_filename) do |tmp_file|
  medium.file = tmp_file
  medium.save!
end

```

Transaction will automatically delete (`unlink`) the temporary file after block
finish. If you want to keep the tmp file for longer you can use:

```
file = PullTempfile.pull_tempfile(url: url, original_filename: original_filename)
# ...
file.unlink # delete file
```


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


## Reason why this Gem exist:

When you using gem like [paperclip](https://github.com/thoughtbot/paperclip) `> 3.1.4` you can do something like this to pull file from url:

```ruby
class User < ActiveRecord::Base
  attr_reader :avatar_remote_url
  has_attached_file :avatar

  def avatar_remote_url=(url_value)
    self.avatar = URI.parse(url_value)
    # Assuming url_value is http://example.com/photos/face.png
    # avatar_file_name == "face.png"
    # avatar_content_type == "image/png"
    @avatar_remote_url = url_value
  end
end

user = User.new
user.avatar_remote_url = 'http://example.com/photos/face.png'
user.save!
```

And this is how you upload file from url.

> source
> https://github.com/thoughtbot/paperclip/wiki/Attachment-downloaded-from-a-URL

The problem is that if you do this on AWS S3 signd url is sending binary mime type
`binary/octet-stream` and therefore
if you are implementing validations on your uploads:

```
class User < ActiveRecord::Base
  # ...
  validates_attachment_content_type :avatar, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]
  # ...
end
```

...you'll get error:

```
Validation failed: File has contents that are not what they are
reported to be, File is invalid, File content type is invalid
```

One solution is to skip validations in this context:

```ruby
#...
medium.save!(validate: false)  # will skip validations
```

...but that's not secure.

> Yes you can use context validations, or implement validations differently
> http://www.eq8.eu/blogs/22-different-ways-how-to-do-rails-validations
> but that's not the point,

So way how to get around this is to  download the file to your `/tmp/` folder as a temp
file, and upload it via Paperclip

Install gem `httparty`

```
# Gemfile
# ...
gem 'httparty'
# ...
```

Run `bundle install`


Next create new file `./lib/s3_helper.rb`

```
require 'httparty'      # gem
module S3Helper
  def pull_asset(url:, destination:)
    File.open(destination, "wb") do |f|
      f.binmode
      f.write HTTParty.get(url).parsed_response
      f.close
    end
  end
end
```

And now you can do something like:

```ruby
user = User.new
require Rails.root.join('lib', 's3_helper')

S3Helper.pull_asset(url: "http://s3....../bbuesubeueueue", destination: "/tmp/my-file.jpg")

user.avatar = File.open("/tmp/my-file.jpg")
user.save!
```

But the problem is that you need to delete this file manually. So why
not to take advantage of Ruby `Tempfile`. This is exactly what this gem
is doing. Have a look on the Source code  https://github.com/equivalent/pull_tempfile/blob/master/lib/pull_tempfile.rb
