#! /usr/bin/env ruby
require 'socket'


s = TCPSocket.new 'localhost', 1234

name = "Ben's Team"
key = '1234567890098765432112345'
packet = [314, name.length, name, 42, key.length, key].pack("n2a#{name.length}n2a#{key.length}")
s.write(packet)
s.close_write
puts s.read.unpack("n2a*")[2]
s.close()
