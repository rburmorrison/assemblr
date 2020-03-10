# frozen_string_literal: true

$VERBOSE = nil

require 'tty-logger'

##
# Define the core Assemblr methods.
module Assemblr
  @@options = []
  @@error_hook = -> {}

  def set_option(key, value)
    return unless @@options.include?(key.to_sym)

    Assemblr.class_variable_set("@@#{key}", value)
  end

  def get_option(key)
    Assemblr.class_variable_get("@@#{key}")
  end

  def define_option(name, value)
    Assemblr.class_variable_set("@@#{name}", value)
    @@options << name.to_sym
  end

  def options
    Assemblr.class_variable_get('@@options')
  end

  def error_hook
    @@on_error
  end

  def on_error(&block)
    @@on_error = block
  end

  ##
  # Generates method definitions in all supported styles.
  def expose_method(name)
    prefix = to_s.downcase.gsub('::', '_').delete_prefix('assemblr_')
    eval "#{self}.define_method(:#{prefix}_#{name}, &#{self}.method(:#{name}))"
    eval "#{self}.define_singleton_method(:#{name}, &#{self}.method(:#{name}))"
  end
end

include Assemblr

module Assemblr
  ##
  # Define some quick-and-easy logging methods.
  module Log
    define_option :log, true
    define_option :log_error_hook, true

    TTYLogger = TTY::Logger.new do |config|
      config.metadata = %i[time date]
    end

    def self.included(_)
      expose_method :info
      expose_method :success
      expose_method :warn
      expose_method :error
    end

    class << self
      ##
      # @!method info(message)
      # Logs an info message.
      #
      # @return [void]

      ##
      # @!method success(message)
      # Logs a success message.
      #
      # @return [void]

      ##
      # @!method warn(message)
      # Logs a warning message.
      #
      # @return [void]
      %i[info success warn].each do |level|
        define_method level do |*args, &block|
          TTYLogger.send(level, *args, &block) if get_option(:log)
        end
      end

      ##
      # @!method error(message)
      # Logs a error message. If configured, this will call the on_error proc
      #
      # @return [void]
      define_method :error do |*args, &block|
        TTYLogger.send(:error, *args, &block) if get_option(:log)
        error_hook.call if get_option(:log_error_hook)
      end
    end
  end
end

include Assemblr::Log
