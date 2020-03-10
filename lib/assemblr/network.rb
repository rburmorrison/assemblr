# frozen_string_literal: true

$VERBOSE = nil

require 'assemblr'

require 'socket'
require 'net/ping'

module Assemblr
  ##
  # Defines methods for common network functions.
  module Network
    def self.included(_)
      expose_method :local_ip
      expose_method :ip_reachable?
    end

    class << self
      ##
      # Retrieve the first ip address that is not '127.0.0.1' on the local
      # machine.
      #
      # @param pattern [Regexp] a pattern to test the IPs against
      #
      # @return [String]
      def local_ip(pattern = //)
        Socket.ip_address_list.each do |ip|
          address = ip.ip_address
          next if address == '127.0.0.1'
          return address if address.match?(pattern)
        end
        ''
      end

      ##
      # Check if a remote ip can be contacted.
      #
      # @return [Boolean]
      def ip_reachable?(ip)
        external = Net::Ping::External.new(ip)

        log_info %(attempting to contact host "#{ip}")
        reachable = external.ping || external.ping6
        if reachable
          log_success %(host "#{ip}" is reachable)
        else
          log_error %(unable to contact host "#{ip}")
        end

        reachable
      end
    end
  end
end

include Assemblr::Network
