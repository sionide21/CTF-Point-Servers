module SimpleProtocol
  # The simple protocol
  # This protocol is basically just (Type, Length, Value) for each element
  # The Type and length are each 2 byte network order unsigned numbers
  # There are two elements: name and key
  # Name is type 99 and has a max length of 127
  # Key is type 42 requiring exactly 25 digits as a string
  NAME = 99
  KEY = 42

  def self.read(conn)
    name = nil, key = nil
    while header = conn.read(4)
      type, length = header.unpack('nn')
      $logger.debug("Type: #{type}, Length: #{length}")
      if type == NAME
        if length > 127
          raise "Name too long"
        end
        name = conn.read(length)
        $logger.debug("Decoded name: #{name}")
      elsif type == KEY
        if length != 25
          raise "Invalid key length"
        end
        key = conn.read(length)
        $logger.debug("Decoded key: #{key}")
        if key.to_i.to_s != key
          raise "Key not decimal number"
        end
      else
        raise "Invalid type: #{type}"
      end
    end
    if not (key and name)
      raise "Missing fields"
    end
    return { name: name, key: key }
  end
end
