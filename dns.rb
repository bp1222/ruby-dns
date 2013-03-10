#!/usr/bin/ruby -w

require 'thread'
require 'socket'

$read_mutex = Mutex.new
$send_mutex = Mutex.new

class DNSServer
	def initialize
		@server = UDPSocket.new
		@server.bind("127.0.0.1", 53)
	end

	def listen
		loop {
			udp_packet = @server.recvfrom(512)
			Thread.new(udp_packet) {
				$read_mutex.synchronize do
					Thread.current[:packet] = udp_packet
					puts "running parser"
					Thread.current[:parser] = DNSRequest.new(udp_packet[0].chomp)
				end

				Thread.current[:parser].buildResponse

				$send_mutex.synchronize do
					puts Thread.current[:parser].response
				end
			}
		}
	end
end

class DNSRequest
	attr_accessor :response

	def initialize (packet)
		@dns_packet = packet.unpack('H4B16H4H4H4H4H*')
	end
end


if __FILE__ == $0
	server = DNSServer.new
	server.listen
end
