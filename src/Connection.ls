require! \net
require! \events

ParserStream = require \./ParserStream
SerializerStream = require \./SerializerStream

module.exports = class Connection extends events.EventEmitter

  /* Constructor */

  (options = {}) ~>
    super!
    @{nickname, username, realname} = options
    @username ?= @nickname
    @realname ?= @nickname

  /* Prototype methods */

  connect: (...args) ~>
    @{port, host} = parseSocketOptions ...args
    @socket = net.createConnection @port, @host
    @socket.pipe (@parser = new ParserStream)
    (@serializer = new SerializerStream).pipe @socket

    @parser.on \readable, ~>
      while (message = @parser.read!)?
        @emit \raw, message

    @serializer.write command: \NICK, parameters: [@nickname]
    @serializer.write command: \USER, parameters: [@username, 0, 0, @realname]

/* Helper functions */

function parseSocketOptions ...args
  tryAsObject = (obj) ->
    if typeof obj is \object
      validHost = typeof obj.host is \string
      validPort = typeof obj.port is \number
      if validHost or validPort
        if not validHost then obj.host = \localhost
        else if not validPort then obj.port = 6667
        obj
  trySeparate = (port, host) ->
    if typeof port is \number
      if typeof host isnt \string then host = \localhost
      { port, host }
    else if typeof port is \string
      if typeof host isnt \number then host = 6667
      { port: host, host: port }

  (tryAsObject ...args) or (trySeparate ...args) or throw new Error 'Invalid socket options'
