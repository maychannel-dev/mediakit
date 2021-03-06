# Mediakit

[![Circle CI](https://circleci.com/gh/ainame/mediakit/tree/master.svg?style=svg)](https://circleci.com/gh/ainame/mediakit/tree/master) [![Code Climate](https://codeclimate.com/github/ainame/mediakit/badges/gpa.svg)](https://codeclimate.com/github/ainame/mediakit)

mediakit is the libraries for ffmpeg and sox backed media manipulation something.
I've design this library for following purpose.

* have low and high level interfaces as you like use
* easy testing design by separation of concern

## Development Plan

Currently you can use low-level inteface of mediakit!

* [x] low-level interface
  * [x] execute command for ffmpeg as a code
  * [x] unit testing supports (fake driver)
  * [x] nice command setting
  * [x] read timeout setting
  * [x] shell escape for security
  * [x] ffmpeg instropection (retrive supported formats, codecs, encoders and decoders)
  * [x] logger support
  * [x] formats, codecs, encoders and decoders representation as a code
* [ ] low-level ffprobe interface
* [ ] high-level interface for ffmpeg
* [ ] low-level interface for sox
* [ ] high-level interface for sox

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mediakit'
```

And then execute:

    $ bundle

Or install it yourself as:

$ gem install mediakit

## Requirements

This library behave command wrapper in your script.
So it need each binary command file.

* latest ffmpeg which have ffprobe command

## Usage

### Low Level Interface

The low level means it's near command line usage.
This is a little bore interface for constructing options,
but can pass certain it.

```rb
driver = Mediakit::Drivers::FFmpeg.new()
ffmpeg = Mediakit::FFmpeg.new(driver)

options = Mediakit::FFmpeg::Options.new
options.add_option(Mediakit::FFmpeg::Options::GlobalOption.new('t' => 100))
options.add_option(Mediakit::FFmpeg::Options::InputFileOption.new(options: nil, path: input))
options.add_option(
  Mediakit::FFmpeg::Options::OutputFileOption.new(
    options: {
      'vf' => 'crop=320:320:0:0',
      'ar' => '44100',
      'ab' => '128k',
    },
    path:    output,
  )
)
puts "$ #{ffmpeg.command(options)}"
puts ffmpeg.run(options, timeout: 30, nice: 0)
```

#### Drivers

mediakit has two drivers for execute command. First, Popen Driver is implemented by Open3#popen3 that is main driver. Second, FakeDriver is the fake object for unit-testing.

##### Driver Usage

instatiate

```ruby
default_driver = Mediakit::Drivers::FFmpeg.new # default is popen driver
driver = Mediakit::Drivers::FFmpeg.new(:popen) # explicitly use popen driver
fake_driver = Mediakit::Drivers::FFmpeg.new(:fake) # fake driver
```

testing

```ruby
# setup
fake_driver = Mediakit::Drivers::FFmpeg.new(:fake)
fake_driver.output = 'output'
fake_driver.error_output = 'error_output'
fake_driver.exit_status = true
ffmpeg = Mediakit::FFmpeg.new(fake_driver)

# excursie
options = Mediakit::FFmpeg::Options.new(
  Mediakit::FFmpeg::Options::GlobalOption.new(
    'version' => true,
  ),
}
out, err, exit_status = ffmpeg.run(options)

# verify
assert_equal(fake_driver.last_command, 'ffmpeg -version')
assert_equal(out, 'output')
assert_equal(err, 'error_output')
assert_equal(exit_status, true)

# teardown
fake_driver.reset
```

### Formats/Codecs/Decoders/Encoders

FFmpeg has so many formats, codecs, decoders and encoders.
So, mediakit provide constant values for presenting those resources as a code.

```rb
ffmpeg = Mediakit::FFmpeg.create
ffmpeg.init

# can use after call Mediakit::FFmpeg#init
Mediakit::FFmpeg::AudioCodec::CODEC_MP3 #=> #<Mediakit::FFmpeg::AudioCodec:0x007fb514040ad0>
Mediakit::FFmpeg::AudioCodec::CODEC_MP3.name #=> "mp3"
Mediakit::FFmpeg::AudioCodec::CODEC_MP3.desc #=> "MP3 (MPEG audio layer 3)"
...

```

These values reflect your ffmpeg binary build conditions by automate.
`Mediakit::FFmpeg::AudioCodec::CODEC_MP3` is just a instance of Mediakit::FFmpeg::AudioCodec class.
### High Level Interface

TBD

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mediakit/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## References

* [streamio/streamio-ffmpeg](https://github.com/streamio/streamio-ffmpeg)
* [ruby-av/av](https://github.com/ruby-av/av)
* [Xuggler](http://www.xuggle.com/xuggler/)
* [PHP-FFMpeg/PHP-FFMpeg](https://github.com/PHP-FFMpeg/PHP-FFMpeg)
