# frozen_string_literal: true

require 'assemblr'

require 'timeout'
require 'net/ssh'
require 'net/scp'

module Assemblr
  ##
  # Defines methods to handle interacting with remote nodes.
  module Remote
    @@nodes = []

    define_option :remote_default_group, :default
    define_option :remote_default_user, 'root'

    def self.included(_)
      expose_method :group
      expose_method :upload
      expose_method :exec
      expose_method :current_nodes
      expose_method :node
      expose_method :nodes
    end

    class << self
      ##
      # Defines methods availabile only while in a group block.
      module Group
        def self.remote_upload(src, dest, recursive: false, timeout: 5)
          Remote.current_nodes.each do |n|
            Remote.upload(n[:ip], n[:user], src, dest,
                          recursive: recursive,
                          timeout: timeout)
          end
        end

        def self.remote_exec(cmd, inject: [])
          results = []
          Remote.current_nodes.each do |n|
            result = Remote.remote_exec(n[:ip], n[:user], cmd, inject: inject)
            results << result
          end
          results
        end
      end

      # Execute a command on a remote machine using SSH. It returns the
      # combined stdout and stderr data.
      #
      # @param ip [String] the ip of the node to run the command on
      # @param user [String] the user to log in as
      # @param cmd [String] the command to execute remotely
      # @param inject [Array<String>] strings to inject into stdin
      #
      # @return [String]
      def exec(ip, user, cmd, inject: [])
        log_info "attempting to execute `#{cmd}` on #{user}@#{ip}"

        result = ''
        exit_code = 0
        Net::SSH.start(ip, user) do |ssh|
          ch = ssh.open_channel do |ch|
            ch.exec(cmd) do |ch, success|
              log_error "unable to execute `#{cmd}` on #{user}@#{ip}" unless success

              # Collect stdout data.
              ch.on_data do |_, data|
                result += data if data.is_a?(String)
              end

              # Collect stderr data.
              ch.on_extended_data do |_, _, data|
                result += data if data.is_a?(String)
              end

              inject.each do |line|
                ch.send_data(line + "\n")
              end

              ch.on_request 'exit-status' do |_, data|
                exit_code = data.read_long
                if exit_code.zero?
                  log_success "`#{cmd}` executed successfully on #{user}@#{ip}"
                else
                  log_error "`#{cmd}` returned status code #{exit_code} on #{user}@#{ip}"
                end
              end
            end
          end

          ch.wait
        end
        [result, exit_code]
      end

      ##
      # Return all nodes within the current default group.
      #
      # @return [Array<Hash{ip=>String, group=>String, user=>String}>]
      def current_nodes
        return nodes if get_option(:remote_default_group) == 'all'

        @@nodes.select { |n| n[:group] == get_option(:remote_default_group).to_s }
      end

      ##
      # Temporarily change the default group to refer to the specified group
      # while within the passed block.
      #
      # This method also changes the behavior of `remote_exec` and
      # `remote_upload` while within the given block. Both functions don't take
      # an IP # and a user, as they collect the information for all nodes
      # within the group. In that case, the return value is an array of the
      # results given by each node.
      #
      # @param group [Symbol] the group to temporarily switch to
      #
      # @return [void]
      def group(group, &block)
        log_info %(entered group block with group "#{group}")

        # Temporarily switch to the target group.
        old_default_group = get_option(:remote_default_group)
        set_option(:remote_default_group, group.to_s)

        Group.class_eval(&block)

        set_option(:remote_default_group, old_default_group)

        log_info %(exited group block with group "#{group}")
      end

      ##
      # Upload a file or directory to a node.
      #
      # @param ip [String] the node to upload to
      # @param user [String] the user to authenticate as
      # @param src [String] the file to upload
      # @param dest [String] the location to upload to
      # @param recursive [Bool] recursively upload files in a directory
      # @param timeout [Integer] how many seconds to wait before throwing an error
      #
      # @return [void]
      def upload(ip, user, src, dest, recursive: false, timeout: 5)
        log_info %(attempting to upload "#{src}" to #{user}@#{ip}:#{dest})
        Timeout.timeout timeout do
          Net::SCP.upload!(ip, user, src, dest, recursive: recursive)
        end
      rescue Timeout::Error
        log_error %(failed to upload "#{src}" to #{user}@#{ip}:#{dest} within #{timeout} seconds)
      rescue StandardError
        log_error %(failed to upload "#{src}" to #{user}@#{ip}:#{dest})
      else
        log_success %(uploaded "#{src}" to #{user}@#{ip}:#{dest})
      end

      ##
      # Add a node to the list of nodes.
      #
      # @param ip [String] the ip address of the node
      # @param group [Symbol] the group to assign the node to
      # @param user [String] the user to associate with the node
      #
      # @return [Hash{ip=>String, group=>String, user=>String}] the added node
      def node(ip,
               group: get_option(:remote_default_group),
               user: get_option(:remote_default_user))
        group = group.to_s
        if group == 'all'
          message = 'nodes can not be assigned to the "all" group'
          error = ArgumentError.new(message)
          raise error
        end

        l_node = { ip: ip, group: group, user: user }
        @@nodes << l_node
        log_info "added node: #{l_node}"

        l_node
      end

      ##
      # Get all registered nodes.
      #
      # @return [Array<Hash{ip=>String, group=>String, user=>String}>]<Paste>
      def nodes
        @@nodes
      end
    end
  end
end

include Assemblr::Remote
