# fig_tree

Create nested, easy-to-use configuration for your gem or application, which also allows defining
*lists* of configuration objects that can be fetched later on. Loosely similar to the
[dry-configurable](https://github.com/dry-rb/dry-configurable) gem but with several advantages.

<p align="center">
  <a href="https://badge.fury.io/rb/fig_tree"><img src="https://badge.fury.io/rb/fig_tree.svg" alt="Gem Version" height="18"></a>
  <a href="https://codeclimate.com/github/flipp-oss/fig_tree/maintainability"><img src="https://api.codeclimate.com/v1/badges/a5fc45a193abadc4e45b/maintainability" /></a>
</p>

# Installation

Add this line to your application's Gemfile:
```ruby
gem 'fig_tree'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fig_tree

# Versioning

We use a version of semver for this gem. Any change in previous behavior 
(something works differently or something old no longer works)
is denoted with a bump in the minor version (0.4 -> 0.5). Patch versions 
are for bugfixes or new functionality which does not affect existing code. You
should be locking your Gemfile to the minor version:

```ruby
gem 'fig_tree', '0.0.1'
```

# Usage

FigTree allows you to define the *shape* of your configuration and then configure it in a number
of elegant ways.

## Defining configurations

FigTree is designed to be included in a class that *has a* configuration. Here's an example:

```ruby
class FileCreator
  include FigTree
  
  define_settings do
    setting :enabled, true # default is true
    setting :file_owner # default is nil
    setting :logger, default_proc: proc { Rails.logger } # execute the proc to figure out the default value
    setting :allowed_directories, ['app/lib', 'app/'] # set default to any object
    setting(:after_create, proc { }) # default is a proc that does nothing
  end  
end
```

You can then configure your class in a nice DSL:

```ruby
FileCreator.configure do
  enabled false
  file_owner "john.smith"
  after_create do
    puts "Done!"
  end
end
```

If you like, you can pass the config object as an argument (the `=` are optional):

```ruby
FileCreator.configure do |config|
  config.enabled = false 
  config.file_owner = "john.smith"
  config.after_create do
    puts "Done!"
  end
end
```

Or you can just modify it directly:

```ruby
FileCreator.config.enabled = false
```

You can reference the settings quite easily:

```ruby
FileCreator.config.file_owner # john.smith
FileCreator.config.logger # Rails.logger, even if it didn't exist at the time the configuration
                          # was defined
FileCreator.config.after_create.call # puts "Done!"
```

You can call `configure` multiple times without issue. Each `configure` call will add onto the
previous one.

### Nested configurations

You can create configuration namespaces by simply passing a block to the `setting` method:

```ruby
class FileCreator
  include FigTree
  
  define_settings do
    setting :file_options do
      setting :permissions do
        setting :user_read
        setting :user_write
      end
      setting :group_name
    end
  end  
end

# configuring

FileCreator.configure do
  # you can nest your configuration like so:
  file_options do
    group_name "wheel"
  end
  # or you can namespace them:
  file_options.permissions.user_read = true
end

# reading works the same way
FileCreator.config.file_options.group_name # wheel
```

### Defining "setting lists"

FigTree allows you to define the structure of a configurable object which you can create multiples
of. An example might be a number of message consumers, or a number of file processors.

```ruby
class Consumers
  include FigTree
  
  define_settings do
    setting_object :consumer do
      setting :name
      setting :topic
      setting :broker do
        setting :timeout, 60.seconds
      end
    end
  end  
end

# configuring

Consumers.configure do
  consumer do
    name "users"
    setting "Users.User"
    broker.timeout 5.seconds
  end
end

# reading uses the special `consumer_objects` method to retrieve the setting objects with the name
# "consumer"
timeouts = FileCreator.config.consumer_objects.map { |c| c.broker.timeout }
```

### Deprecations

You can set up a deprecation of an old config path to a new one thusly:

```ruby
FileCreator.define_settings do
  deprecate 'user_read', 'file_options.user_read'
end
```

Users can then still use the old config, which will be automatically mapped to the new one:

```ruby
FileCreator.user_read = true
# will set `file_options.user_read` instead, and print out a deprecation warning:
# config.user_read is deprecated - use config.file_options.user_read
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/flipp-oss/fig_tree .

### Linting

FigTree uses Rubocop to lint the code. Please run Rubocop on your code 
before submitting a PR.

---
<p align="center">
  Sponsored by<br/>
  <a href="https://corp.flipp.com/">
    <img src="support/flipp-logo.png" title="Flipp logo" style="border:none;"/>
  </a>
</p>
