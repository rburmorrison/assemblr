# frozen_string_literal: true

require 'tty-logger'

module Assemblr
  Logger = TTY::Logger.new do |config|
    config.metadata = %i[time date]
  end

  m_log = true
  m_quit_on_error = true

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
      return unless m_log

      Logger.send(level, *args, &block)
    end
  end

  ##
  # @!method error(message)
  # Logs a error message. If configured, this will end the task with error code
  # 1.
  #
  # @return [void]
  define_method :error do |*args, &block|
    Logger.send(:error, *args, &block) if m_log
    exit 1 if m_quit_on_error
  end
end
