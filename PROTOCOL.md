CTF Points Protocol
===================

This server speaks 3 related protocols: `EASY`, `MEDIUM`, and `HARD`.

All three are simple TLV (Type, Length, Value) binary protocols. Each field is encoded as:

* Type: 16 bit network order short
* Length: 16 bit network order short
* Value: n bytes where n is the value of the Length field

## EASY

The request for easy uses 2 fields:

* `NAME` - Type: 314, Length: <= 127 The team name
* `KEY` - Type: 42, Length: 25 The flag being submitted

The server responds with `RESULT`:

* `KEY` - Type: 7 'OK' if success, 'KERNEL WHO?' otherwise

## MEDIUM

Medium is a wrapper for `EASY` that adds a checksum.

Request:

* `BODY` - Type: 5 A full `EASY` packet
* `HASH` - Type: 19780 ("MD"), Length: 16 An MD5 hash of the entire `EASY` packet (Not hex encoded)

The response is the same as the request except the contents of `BODY` is an `EASY` response.

## HARD

Hard is a wrapper for `MEDIUM` that encrypts the entire `MEDIUM` packet.

The encryption is done with AES 256 CBC mode. The IV is all 0 bytes (The default in openssl if one is not specified)

Request:

* `BODY` - Type: 256 A full `MEDIUM` packet
* `KEY` - Type: 17218, Length: 32 (256 bits) The encryption key
* `HINT` - Type: 1337, Length: 3 The string "AES" as a hint in the pcap files

Response:

* `BODY` - Type: 256 A full `MEDIUM` packet encrypted with the key passed in the request
* `HINT` - Type: 1337, Length: 3 The string "AES" as a hint in the pcap files
