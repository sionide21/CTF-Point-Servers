#! /usr/bin/env ruby

require 'socket'
require 'logger'
require './protocols'

# Listen on this port
PORT = 1234
# Use INFO in normal cases, DEBUG will provide a lot of extra data if needed
LOGLEVEL = Logger::INFO
# File to store captures
RESULTS = "winners.txt"
# File to lookup flags
FLAGS = "flags.txt"


$logger = Logger.new(STDOUT)
$logger.level = LOGLEVEL
$lock = Mutex.new

flags = []
File.open(FLAGS) do |file|
  flags = file.readlines.map { |s| s.strip }
  $logger.info("Loaded #{flags.length} flags.")
end

socket = TCPServer.new "0.0.0.0", PORT

loop do
  Thread.start(socket.accept) do |conn|
    begin
      $logger.debug "Accepted connection from #{conn.peeraddr(:numeric)[3]}"
      input = PeekableIO.new conn
      server = Protocols.determine_protocol input
      $logger.debug "Using protocol: #{server.class}"
      packet = server.read(input)
      $logger.info(packet)
      if flags.include? packet[:key]
        server.send_result(conn, true)
        $lock.synchronize do
          File.open(RESULTS, 'a') do |f|
            f.puts "#{Time.now} #{server.class} #{packet[:name]}: #{packet[:key]}"
          end
        end
      else
        server.send_result(conn, false)
      end
    rescue Exception => e
      $logger.debug(e)
    end
    conn.close rescue nil
  end
end