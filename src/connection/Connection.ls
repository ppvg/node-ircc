require! net
require! events
require! \./protocol/ParserStream
require! \./protocol/SerializerStream

module.exports = class Connection extends events.EventEmitter

  ~>
    @serializer = new SerializerStream
    @parser = new ParserStream
    @parser.on \readable, ~>
      while (message = @parser.read!)?
        @emit \message, message

  connect: (...args) ->
    if @socket? then throw new Error 'Already connected'
    @socket = net.createConnection ...args
    @serializer.pipe @socket
    @socket.pipe @parser
    @socket.on \close, ~> @emit \close

  close: ->
    if not @socket?
      throw new Error 'Already disconnected'
    @serializer.unpipe @socket
    @socket.unpipe @parser
    @socket.end!
    delete @socket
    @serializer = new SerializerStream
    @parser = new ParserStream

  send: (...args) ->
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
