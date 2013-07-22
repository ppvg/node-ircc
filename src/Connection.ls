require! net
require! events
require! \./ParserStream
require! \./SerializerStream

module.exports = class Connection extends events.EventEmitter

  ~>
    @serializer = new SerializerStream
    @parser = new ParserStream
    @parser.on \readable, ~>
      while (message = @parser.read!)?
        @emit \message, message

  connect: (...args) ~>
    if @socket? then throw new Error 'Already connected'
    @socket = net.createConnection ...args
    @serializer.pipe @socket
    @socket.pipe @parser, { end: false }
    @socket.on \close, ~> @emit \close
    @socket.on \connect, ~> @emit \connect
    @socket.on \error, (error) ~> @emit \error, error

  close: ~>
    if not @socket? then throw new Error 'Already disconnected'
    @serializer.unpipe @socket
    @socket.unpipe @parser
    @socket.end!
    delete @socket

  send: (...args) ~>
    if not @socket? then throw new Error 'Not connected'

    command = args[0]
    parameters = args.slice 1

    switch (typeof! command)
    | \Object
      if not command? or typeof command.command isnt \string
        throw new Error 'Invalid command'
      message = command
    | \String
      message = { command }
      if parameters.length > 0 then message.parameters = parameters.map toString
    | otherwise
      throw new Error 'Invalid command'

    @serializer.write message

function toString obj
  if obj? then obj = obj.toString!
  obj
