require! fs
require! net
require! events

module.exports = class SingletonServer extends events.EventEmitter
  ~>
    @server = net.createServer!
    @server.on \error, @_onError
    @server.on \connection, @_onConnection
    @server.on \listening, ~> @emit \listening
    @server.on \close, ~> @emit \close
    @client = null

  listen: (@path) ->
    @server.listen @path

  close: ->
    if @client? then @client.end!
    @server.close!

  _onError: (error) ~>
    if error.code is \EADDRINUSE
      sock = net.createConnection @path
      sock.on \connect, ~>
        sock.end!
        @emit \superfluous
      sock.on \error, (error) ~>
        if error.code is \ECONNREFUSED
          fs.unlink @path
          @listen @path
    else
      @emit \error, error

  _onConnection: (socket) ~>
    if @client?
      socket.end!
      socket.on \error, -> void
    else
      @client = socket
      socket.on \close ~> @client = null
      socket.on \error, ~> @client = null
      @emit \connection, socket