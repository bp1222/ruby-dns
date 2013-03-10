#!/usr/bin/ruby -w

require 'thread'
require 'socket'

$read_mutex = Mutex.new
$send_mutex = Mutex.new

$faux_records = {
	'com' => {
		'google' => {
			'a' => '129.21.60.41',
			'aaaa' => 'feed:beef::'
		}
	}
}

class String
	def convert_base(from, to)
		self.to_i(from).to_s(to)
	end

	def hex_to_ascii
		self.scan(/../).map { |x| x.hex.chr }.join
	end

	def hex_to_ascii!
		self.replace(self.hex_to_ascii)
	end
end

class DNSResolver
	def initialize (query_str)
		@query = Array.new
		query_parse = Array.new

		query_str.scan(/../).map { |x| query_parse.push(x) }

		while count = query_parse.shift do
			query_bit = ""
			count = count.convert_base(16,10).to_i
			if (count == 0)
				break
			end

			until count < 1
				count -= 1
				query_bit += query_parse.shift
			end

			@query.unshift(query_bit)
		end
	end

	def checkCache
		while $faux_records.has_key?(@query[i].hex_to_ascii)
			i += 1
		end
	end

	def resolve
		answer = self.checkCache
	end
end

class DNSRequest
	attr_accessor :response

	def initialize (packet)
		@dns_packet = packet.unpack('H4B16H4H4H4H4H*')
	end

	def resolve
		resolver = DNSResolver.new @dns_packet[6]
		resolver.resolve
	end
end

#		response = [
#			@dns_packet[0],
#			"0011000100110000",
#			"0001",
#			"0001",
#			"0000",
#			"0000",
#			@dns_packet[6],
#			"c00c00010001000000f500044a7de440"
#		]
#		@response = response.pack('H4B16H4H4H4H4H*H*')

if __FILE__ == $0
	socket = UDPSocket.new
	socket.bind("127.0.0.1", 53)

	loop {
		udp_packet = socket.recvfrom(512)
		Thread.new(udp_packet) {
			$read_mutex.synchronize do
				Thread.current[:packet] = udp_packet
				Thread.current[:parser] = DNSRequest.new(udp_packet[0].chomp)
			end

			Thread.current[:parser].resolve

			$send_mutex.synchronize do
				sender = Thread.current[:packet][1]
				socket.send(Thread.current[:parser].response, 0, sender[3], sender[1])
			end
		}
	}
end
