# gelf

A GELF compatible logger http://docs.graylog.org/en/latest/pages/gelf.html

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  gelf:
    github: benoist/gelf-crystal
```


## Usage

```crystal
require "gelf"

logger ||= GELF::Logger.new("localhost", port, "WAN").configure do |config|
  config.facility = "gelf-cr"
  config.host     = "localhost"
  config.level    = Logger::DEBUG
end

logger.debug("some debug message")
logger.info("some info message")

logger.debug({ "short_message" => "some short message", "_extra_var" => "some var"}) # also set the short message
```

## Contributing

1. Fork it ( https://github.com/[your-github-name]/gelf/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
