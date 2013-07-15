require! fs
require! net
require! events

module.exports = class SingletonServer extends events.EventEmitter
  (@path) ->
    @server = net.createServer!
    @server.on \error, @_onError
    @server.on \connection, @_onConnection
    @server.on \listening, ~> @emit \listening
    @server.on \close, ~> @emit \close
    @client = null

  start: ->
    @server.listen @path

  close: ->
    if @client? then @client.end!
    @server.close!

  _onError: (error) ~>
      if error.code is \EADDRINUSE
        sock = net.createConnection path, ~>
          @emit \error, new Error 'Server already running'
        sock.on \error, (error) ~>
          if error.code is \ECONNREFUSED
            fs.unlink @path
            @start!

  _onConnection: (socket) ~>
    if @client?
      socket.end!
    else
      (@client = socket).on \close ~> @client = null
      @emit \connection, socket

