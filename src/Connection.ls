require! net
require! events
require! \./ParserStream
require! \./SerializerStream

module.exports = class Connection extends events.EventEmitter

  /* Constructor */

  (options = {}) ~>
    super!
    @{nickname, username, realname} = options
    @username ?= @nickname
    @realname ?= @nickname

  /* Prototype methods */

  connect: (...args) ->
    if @_connected then throw new Error 'Already connected'
    @{port, host} = normalizeConnectArgs ...args
    @socket = net.createConnection @port, @host
    @socket.pipe (@parser = new ParserStream)
    (@serializer = new SerializerStream).pipe @socket
    @_connected = true

    @parser.on \readable, ~>
      while (message = @parser.read!)?
        handleMessage.call @, message

    @serializer.write command: \NICK, parameters: [@nickname]
    @serializer.write command: \USER, parameters: [@username, 0, 0, @realname]

  disconnect: (message) ->
    invalidQuitMessage = message? and typeof message is not \string
    command = command: \QUIT
    if invalidQuitMessage then throw new Error 'Invalid QUIT message'
    if typeof message is \string then command.parameters = [message]
    @serializer.write command
    @_disconnecting = true

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
      if parameters.length > 0
        message.parameters = normalizeMessageParams parameters
    | otherwise
      throw new Error 'Invalid command'

    @serializer.write message

/* Helper functions */

function normalizeConnectArgs ...args
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

function handleMessage message
  @emit \raw, message
  if message.type is \error
    @emit \error, message
  else if message.command is \ERROR
    if @_disconnecting # (Servers confirm QUIT by responding with ERROR)
      @serializer.unpipe @socket
      @socket.unpipe @parser
      @socket.end!
      @_disconnecting = false
      @_connected = false
      @emit \disconnected
    else
      @emit \error, message
  else
    @emit message.command, message
    @emit message.command.toLowerCase!, message

function normalizeMessageParams input
  concat = (prev, current) -> prev ++ current
  arrayify = (param) ->
    if typeof! param is not \Array
      [param.toString!]
    else
      param
  input.map arrayify .reduce concat
