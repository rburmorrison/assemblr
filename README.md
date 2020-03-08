# Assemblr

A small DSL for the construction of quick automation tasks.

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

This is an example of a simple assemblr script:

```ruby
# frozen_string_literal: true

require 'assemblr'

# Configuration options. The values listed below are the defaults for assemblr.
set :default_user, 'root'     # set the default user nodes are assigned to
set :default_group, 'default' # set the default group nodes are assigned to
set :log, true                # turn on or off built-in logging.
set :quit_on_error, true      # quit if anything goes wrong.

group :dev_servers do
  # Define nodes. All nodes defined in this block will be added to the
  # specified group (:dev_servers). After the block ends, the default user and
  # group will be restored for any other top-level node definitions.
  node '10.0.0.173'
  node '10.0.0.332'
  node '10.0.1.22'
end

node '10.0.0.33' # assigned to group :default and user 'root' as per the
                 # defaults

group :dev_servers do
  upload 'Gemfile', '/tmp/Gemmm' # upload a file to all nodes in a group
  upload 'lib', '/tmp',
         recursive: true # upload a directory to all nodes in a group

  remote_exec 'echo "Hello, world!"'
end

upload_to '10.0.2.43', 'root', 'message.txt', '/home/user/message.txt'
result = remote_exec_on 'ruby', inject: ['puts "Hello, world!"', 'exit']

puts result
```

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
