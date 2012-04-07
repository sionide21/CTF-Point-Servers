#! /usr/bin/env ruby

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