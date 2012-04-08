#! /usr/bin/env ruby
require 'socket'
require 'digest/md5'
require 'openssl'
require 'stringio'

s = TCPSocket.new 'localhost', 1234

name = "Ben's Team"
key = '1234567890098765432112345'

def encode(type, value)
  [type, value.length, value].pack("n2a#{value.length}")
end

# Easy Packet
packet = encode(314, name) << encode(42, key)

# Add hash
hash = Digest::MD5.digest(packet)
packet = encode(5, packet) << encode(19780, hash)

# Encrypt
cipher = OpenSSL::Cipher::AES256.new(:CBC)
cipher.encrypt
key = cipher.random_key
packet = cipher.update(packet) + cipher.final

# Send
s.write(encode(1337, 'AES'))
s.write(encode(17218, key))
s.write(encode(256, packet))

# Flush
s.close_write

# Get the result
io = s
while data = io.read(4)
  type, len = data.unpack('n2')
  val = io.read(len)
  if type == 256
    decipher = OpenSSL::Cipher::AES256.new(:CBC)
    decipher.decrypt
    decipher.key = key
    io = StringIO.new(decipher.update(val) + decipher.final)
  elsif type == 5
    io = StringIO.new(val)
  elsif type == 7
    puts val
  end
end

s.close