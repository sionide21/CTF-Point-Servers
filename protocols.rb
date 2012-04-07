require 'digest/md5'
require 'stringio'

class PeekableIO
  # This is a hack. It takes avantage of the fact
  # that all we use in IO is read. DO NOT USE ELSEWHERE
  def initialize(io)
    @io = io
    @buffer = StringIO.new
  end

  def peek(i)
    data = @io.read(i)
    @buffer = StringIO.new(@buffer.string << data)
    return data
  end

  def read(i)
    data = @buffer.read(i)
    return @io.read(i) unless data
    more = i - data.length
    data << @io.read(more) if more
    return data
  end
end

module Protocols

  def self.determine_protocol(input)
    type = input.peek(2).unpack('n')[0]
    cls = [Easy, Medium].find { |cls| cls.handles(type) }
    raise "Invalid type: #{type}" unless cls
    return cls.new
  end

  class Base
    def read_elements(conn, *elements)
      # Read all TLV elements
      decoded = [nil] * elements.length
      while header = conn.read(4)
        type, length = header.unpack('nn')
        $logger.debug("Type: #{type}, Length: #{length}")
        if not elements.include? type
          raise "Invalid type: #{type}"
        end
        value = conn.read(length)
        $logger.debug("Decoded: #{value}")
        decoded[elements.index(type)] = value
      end
      return decoded
    end

    def encode(type, value)
      length = value.length
      return [type, length, value].pack("n2a#{length}")
    end
  end

  class Easy < Base
    # The simple protocol
    # This protocol is basically just (Type, Length, Value) for each element
    # The Type and length are each 2 byte network order unsigned numbers
    # There are two elements: name and key
    # Name is type 314 and has a max length of 127
    # Key is type 42 requiring exactly 25 digits as a string
    # Results are type 7 and return either OK or KERNEL WHO?
    NAME = 314
    KEY = 42
    RESULT = 7

    def self.handles(input)
      [NAME, KEY].include? input
    end

    def read(conn)
      name, key = read_elements(conn, NAME, KEY)
      if name.length > 127
        raise "Name too long"
      end
      if key.length != 25
        raise "Invalid key length"
      end
      if key.to_i.to_s != key
        raise "Key not decimal number"
      end
      if not (key and name)
        raise "Missing fields"
      end
      return { name: name, key: key }
    end

    # On success, simply send 'OK'
    # On failure, send 'KERNEL WHO?'
    def send_result(conn, success)
      conn.write(encode(RESULT, success ? 'OK' : 'KERNEL WHO?'))
    end
  end

  class Medium < Easy
    # This protocol is an envelope for simple protocol
    # It wraps the entire simple packet in a Type 5
    # Stores an MD5 hash in a type 19780 (its a hint: "MD")
    BODY = 5
    HASH = 19780

    def self.handles(input)
      [BODY, HASH].include? input
    end

    def do_hash(str)
      Digest::MD5.digest(str)
    end

    def read(conn)
      body, hash = read_elements(conn, BODY, HASH)
      $logger.debug("Check Hash: #{do_hash(hash).unpack('H32')} == #{hash.unpack('H32')}")
      if hash != do_hash(body)
        raise "Invalid Hash"
      end
      super(StringIO.new(body))
    end

    def send_result(conn, success)
      body = StringIO.new()
      super(body, success)
      body = body.string
      conn.write(encode(BODY, body))
      conn.write(encode(HASH, do_hash(body)))
    end
  end
end
