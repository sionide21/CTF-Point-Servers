#! /usr/bin/env ruby
require 'socket'
require 'digest/md5'
require 'stringio'

name = "Ben's Team"
key = '1234567890098765432112345'

if ARGV.length == 3
  name = ARGV[1]
  key = ARGV[2]
else
  puts "Usage: #{$0}: <team name> <flag>\n"
  puts "Using sample values: \"#{name}\" \"#{key}\""
end

def encode(type, value)
  [type, value.length, value].pack("n2a#{value.length}")
end

# Connect
s = TCPSocket.new 'localhost', 1234

# Create the easy packet
packet = encode(314, name) << encode(42, key)

# Hash it
hash = Digest::MD5.digest(packet)

# Send
s.write(encode(5, packet))
s.write(encode(19780, hash))

# Flush
s.close_write

# Get the result
io = s
while data = io.read(4)
  type, len = data.unpack('n2')
  val = io.read(len)
  if type == 5
    io = StringIO.new(val)
  elsif type == 7
    puts val
  end
end
s.close
