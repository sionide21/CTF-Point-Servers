#! /usr/bin/env ruby
#
# Copyright (c) 2012 Ben Olive
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'socket'
require 'logger'
require './protocols'

# Listen on this port
PORT = 1234
LOGLEVEL = Logger::INFO
RESULTS = "winners.txt"


$logger = Logger.new(STDOUT)
$logger.level = LOGLEVEL
$lock = Mutex.new
server = TCPServer.new "0.0.0.0", PORT
loop do
  Thread.start(server.accept) do |conn|
    begin
      $logger.debug "Accepted connection from #{conn.peeraddr(:numeric)[3]}"
      packet = SimpleProtocol.read(conn)
      $logger.info(packet)
      $lock.synchronize do
        File.open(RESULTS, 'a') do |f|
          f.puts "#{packet[:name]}: #{packet[:key]}"
        end
      end
    rescue Exception => e
      $logger.fatal(e)
    end
    conn.close rescue nil
  end
end