[![Gem Version](https://badge.fury.io/rb/assemblr.svg)](https://badge.fury.io/rb/assemblr)

# Assemblr

A small DSL for the construction of quick automation tasks.

**NOTE:** This version is just a prototype. It will be completely re-written.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'assemblr'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install assemblr

## Usage

Assemblr is separated into modules. The core module contains simple logging
methods since they're needed by all other modules. It gets automatically
imported when requiring any sub-modules.

Here are the currently existing modules (although none of them are close to
finished):

- `assemblr/shell`
- `assemblr/network`
- `assemblr/remote`

There are currently two styles available to call the methods defined in these
modules:

```ruby
require 'assemblr/shell'

# Style 1
Shell.exec 'my_command'

# Style 2
shell_exec 'my_command'
```

Both styles are automatically imported into the main scope when the file is
required.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can
also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/rburmorrison/assemblr.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
