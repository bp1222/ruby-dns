#!/usr/bin/env ruby

#require "File"
require "YAML"

class DNSZoneReader

	@lastHost = nil

	def initialize( fileName )
		@fileName = fileName
	end

	def read

		File.open( @fileName, "r") do |infile|
			while( line = infile.gets )
				if( line.include?( "(" ) )
					start = line.chomp
					#puts start
					loop {
						line = infile.gets
						li = line.split ";"
						start += li[0]
						#puts start
						if( line.include?( ")" ) )
						#puts start
						line = start
							break
						end
					}
				end
				result = parse line
				puts result.to_yaml
			end
		end
	end

	def parse( line )
		puts line
		#li = line.unpack
		#puts line[0...1]
		case line[0...1]
		when "$"
			#directive
		when ";"
			#comment
		when " "
			la = line.split
			case la[1]
			when /(MX|mx)/
				return MX.new( la[0], la[1], la[2], la[3] )
			end

		when /[A-Za-z]/
			la = line.split
			@lastHost = la[0]
			#puts la.to_yaml
			case la[2]
			when "AAAA"
				return AAAA.new( la[0], la[1], la[2] )
			when /^(A|a)/
				return A.new( la[0], la[1], la[2] )
			when /(MX|mx)/
				return MX.new( la[0], la[1], la[2], la[3] )
			when /(NS)/i
				return NS.new( la )
			when /(SOA)/i
				return SOA.new( la )

			end
		when "\n"
		else
			puts "error parsing: (" + line + ")\n"
		end
	end
end

class DNSRecord
	def initialize ( name = "localhost", netclass = "IN", type = "A", address = "127.0.0.1" )
	end
end

class A < DNSRecord
	def initialize ( name = "localhost", type = "A", address = "127.0.0.1" )
	end
end

class AAAA < DNSRecord
	def initialize ( name = "localhost", type = "AAAA", address = "::1" )
	end
end

class CNAME < DNSRecord
	def initialize ( name = "localhost", type = "CNAME", address = "127.0.0.1" )
	end
end


class MX < DNSRecord
	def initialize ( name = "", type = "MX", priority = "10", address = "mail.local" )
	end
end

class NS < DNSRecord
	def initialize ( arrayArgs )
		@name, @type, @address = arrayArgs
	end
end

class SOA < DNSRecord
	def initialize ( arrayArgs )
#		name = "localhost", type = "SOA", address = "127.0.0.1", serial = 0, refresh = 0, retryVal = 0, expire = 0, negTtl = 0 )
		#puts array
		@name, @type, @address, @serial, @refresh, @retryVal, @expire, @negTtl = arrayArgs
	end
end

class SRV < DNSRecord
	def initialize ( name = "localhost", type = "SRV", address = "127.0.0.1" )
	end
end


if __FILE__ == $0
	#puts ARGV[0]
	config = ARGV[0] == nil ? "simple.zone" : ARGV[0]
	dns = DNSZoneReader.new( config )
	dns.read
end
