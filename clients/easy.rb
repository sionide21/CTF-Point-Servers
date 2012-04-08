#! /usr/bin/env ruby
require 'socket'

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

# Send team name
s.write(encode(314, name))

# Send flag
s.write(encode(42, key))

#Flush
s.close_write

# Get the result
while data = s.read(4)
  type, len = data.unpack('n2')
  val = s.read(len)
  if type == 7
    puts val
  end
end

s.close
