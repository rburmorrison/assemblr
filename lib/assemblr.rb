# frozen_string_literal: true

require 'assemblr/version'
require 'assemblr/logging'
require 'assemblr/utilities'

require 'open3'
require 'net/ssh'
require 'net/scp'

module Assemblr
  $VERBOSE = nil # turn off warnings from external libraries

  # Local variables are prefixed with an 'm' for 'Module' as to not clash with
  # method names.
  m_nodes = []
  m_current_group = 'default'
  m_current_user = 'root'

  ##
  # Set a configuration option.
  #
  # Available options are:
  #
  # - *default_user*  - the default user to assign nodes to
  # - *default_group* - the default group to assign nodes to
  # - *log*           - turn on or off logging
  # - *quit_on_error* - quit if any error occur
  #
  # @return [void]
  define_method :set do |key, value|
    options = %i[log quit_on_error default_user default_group]
    unless options.include?(key)
      raise ArgumentError, "#{key} is not a valid option"
    end

    key = :current_user if key == :default_user
    key = :current_group if key == :default_group

    info %(config: set "#{key}" to "#{value}")
    eval "m_#{key} = value", binding, __FILE__, __LINE__
  end

  ##
  # @!method local_exec(cmd, inject: [])
  # Execute a command locally.
  #
  # @param cmd [String] the command to run locally
  # @param inject [Array<String>] strings to inject into stdin
  #
  # @return [Array(String, Process::Status)]
  define_method :local_exec do |cmd, inject: []|
    log_string = "running `#{cmd}` locally"
    log_string += " with these inputs: #{inject}" unless inject.empty?
    info log_string

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
      error "local command `#{cmd}` exited with a status of #{code}"
    else
      success "local command `#{cmd}` executed successfully"
    end

    return result, status
  end

  ##
  # Execute a command on a remote machine using SSH. It returns the combined
  # stdout and stderr data.
  #
  # @param ip [String] the ip of the node to run the command on
  # @param user [String] the user to log in as
  # @param cmd [String] the command to execute remotely
  # @param inject [Array<String>] strings to inject into stdin
  #
  # @return [String]
  # @return [Array<String>]
  def remote_exec_on(ip, user, cmd, inject: [])
    info "attempting to execute `#{cmd}` on #{user}@#{ip}"

    result = ''
    Net::SSH.start(ip, user) do |ssh|
      ch = ssh.open_channel do |ch|
        ch.exec(cmd) do |ch, success|
          error "unable to execute `#{cmd}` on #{user}@#{ip}" unless success

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
            code = data.read_long
            if code.zero?
              success "`#{cmd}` executed successfully on #{user}@#{ip}"
            else
              error "`#{cmd}` returned status code #{code} on #{user}@#{ip}"
            end
          end
        end
      end

      ch.wait
    end
    result
  end

  ##
  # Upload a file to a node.
  #
  # @param ip [String] the node to upload to
  # @param user [String] the user to authenticate as
  # @param src [String] the file to upload
  # @param dest [String] the location to upload to
  # @param recursive [Bool] recursively upload files in a directory
  # @param timeout [Integer] how many seconds to wait before throwing an error
  #
  # @return [void]
  def upload_to(ip, user, src, dest, recursive: false, timeout: 5)
    info %(attempting to upload "#{src}" to #{user}@#{ip}:#{dest})
    Timeout.timeout timeout do
      Net::SCP.upload!(ip, user, src, dest, recursive: recursive)
    end
  rescue StandardError
    error %(failed to upload "#{src}" to #{user}@#{ip}:#{dest})
  rescue Timeout::Error
    error %(failed to upload "#{src}" to #{user}@#{ip}:#{dest} within #{timeout} seconds)
  else
    success %(uploaded "#{src}" to #{user}@#{ip}:#{dest})
  end

  ##
  # @!method current_nodes()
  # Get all nodes in the current group.
  #
  # @return [void]
  define_method :current_nodes do
    return nodes if m_current_group == 'all'

    nodes.select { |n| n[:group] == m_current_group }
  end

  ##
  # Execute a command on all machines within the current group.
  #
  # @param cmd [String] the command to execute
  # @param inject [Array<String>] strings to inject into stdin
  #
  # @return [String] the combined output of the command
  def remote_exec(cmd, inject: [])
    results = []
    current_nodes.each do |n|
      result = remote_exec_on(n[:ip], n[:user], cmd, inject: inject)
      results << result
    end
    results
  end

  ##
  # Upload a file or directory to all machines within the current group.
  #
  # @param src [String] the file to upload
  # @param dest [String] the location to upload the file to
  # @param recursive [Bool] recursively upload files in a directory
  # @param timeout [Integer] how many seconds to wait before throwing an error
  #
  # @return [void]
  def upload(src, dest, recursive: false, timeout: 5)
    current_nodes.each do |n|
      upload_to(n[:ip], n[:user], src, dest, recursive: recursive)
    end
  end

  ##
  # @!method group(group, &block)
  # Temporarily change current_group to refer to the specified group while
  # within the passed block.
  #
  # @param group [Symbol] the group to temporarily switch to
  #
  # @return [void]
  define_method :group do |group, &block|
    info %(entered group block with group "#{group}")

    # Temporarily switch to the target group.
    old_current_group = m_current_group
    m_current_group = group.to_s

    block.call

    m_current_group = old_current_group

    info %(exited group block with group "#{group}")
  end

  ##
  # @!method current_group
  # Get the current default group.
  #
  # @return [String]

  ##
  # @!method current_user
  # Get the current default user.
  #
  # @return [String]
  %w[group user].each do |item|
    define_method "current_#{item}" do
      eval "m_current_#{item}"
    end
  end

  ##
  # @!method node(ip, group: current_group, user: current_user)
  # Add a node to the list of nodes.
  #
  # @param ip [String] the ip address of the node
  # @param group [Symbol] the group to assign the node to
  # @param user [String] the user to associate with the node
  #
  # @return [Hash{ip=>String, group=>String, user=>String}] the added node
  define_method :node do |ip, group: m_current_group, user: m_current_user|
    group = group.to_s
    if group == 'all'
      error = ArgumentError.new('nodes can not be assigned to the "all" group')
      raise error
    end

    l_node = { ip: ip, group: group, user: user }
    m_nodes << l_node
    info "added node: #{l_node}"

    l_node
  end

  ##
  # @!method nodes()
  # Get all registered nodes.
  #
  # @return [Array<Hash{ip=>String, group=>String, user=>String}>]
  define_method :nodes do
    m_nodes
  end

  define_method :nodes_reachable? do
    reachable = true
    m_nodes.each do |node|
      reachable &&= reachable?(node[:ip])
    end
    reachable
  end
end

extend Assemblr
