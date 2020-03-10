# frozen_string_literal: true

require 'assemblr'

require 'open3'

module Assemblr
  ##
  # Defines methods for common shell commands.
  module Shell
    def self.included(_)
      expose_method :exec
    end

    class << self
      # Execute a command locally.
      #
      # @param cmd [String] the command to run locally
      # @param inject [Array<String>] strings to inject into stdin
      #
      # @return [Array(String, Process::Status)]
      def exec(cmd, inject: [])
        log_string = "running `#{cmd}` locally"
        log_string += " with these inputs: #{inject}" unless inject.empty?
        log_info log_string

        result = ''
        status = nil
        Open3.popen2e(cmd) do |i, o, wait|
          inject.each do |line|
            line = line.strip
            i.write line + "\n"
          end
          i.close
          result = o.read
          status = wait.value
        end

        if status.exitstatus != 0
          code = status.exitstatus
          log_error "local command `#{cmd}` exited with a status of #{code}"
        else
          log_success "local command `#{cmd}` executed successfully"
        end

        [result, status]
      end
    end
  end
end

include Assemblr::Shell
