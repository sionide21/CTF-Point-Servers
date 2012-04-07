#! /usr/bin/env ruby
require 'socket'

name = "Ben's Team"
key = '1234567890098765432112345'

def encode(type, value)
  [type, value.length, value].pack("n2a#{value.length}")
end

s = TCPSocket.new 'localhost', 1234

s.write(encode(314, name))
s.write(encode(42, key))

s.close_write
s.read
s.close()
