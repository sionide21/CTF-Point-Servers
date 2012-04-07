#! /usr/bin/env ruby
require 'socket'
require 'digest/md5'

s = TCPSocket.new 'localhost', 1234

name = "Ben's Team"
key = '1234567890098765432112345'

def encode(type, value)
  [type, value.length, value].pack("n2a#{value.length}")
end

packet = encode(314, name) << encode(42, key)
hash = Digest::MD5.digest(packet)

s.write(encode(5, packet))
s.write(encode(19780, hash))
s.close_write
s.read
s.close