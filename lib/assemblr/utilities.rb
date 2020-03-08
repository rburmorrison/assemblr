# frozen_string_literal: true

require 'socket'
require 'net/ping'

##
# A collection of utility functions for assemblr.
module Assemblr
  ##
  # Retrieve the first ip address that is not '127.0.0.1' on the local machine.
  #
  # @param pattern [Regexp] a pattern to test the ips against
  def get_local_ip(pattern = //)
    Socket.ip_address_list.each do |ip|
      address = ip.ip_address
      next if address == '127.0.0.1'
      return address if address.match?(pattern)
    end
    ''
  end

  ##
  # Check if a remote machine can be contacted.
  #
  # @return [Bool]
  def reachable?(ip)
    external = Net::Ping::External.new(ip)

    info %(attempting to contact host "#{ip}"...)
    reachable = external.ping || external.ping6
    if reachable
      success %(host "#{ip}" is reachable)
    else
      error %(unable to contact host "#{ip}")
    end

    reachable
  end
end
