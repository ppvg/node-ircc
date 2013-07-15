require! [ \dnode \net \fs ]
require! \./Connection

# TODO write unit tests
# TODO refactor to remove references to `process` (move to command.ls)

module.exports = class PersistentConnectionServer
  (@port, @host, @path) ->
    @client = null
    @connection = null
    @server = net.createServer!
    @server.maxConnections = 1
    @server.on \error, @_onError
    @server.on \connection, @_onConnection

  start: ->
    @server.listen @path

  close: ->
    if @client? then @client.end!
    if @connection? then @connection.close!
    @server.close!

  _onError: (error) ~>
    if error.code is \EADDRINUSE
      sock = net.createConnection @path, ~>
        @server.emit \aborted
      sock.on \error, (error) ~>
        if error.code is \ECONNREFUSED
          fs.unlink @path
          @start!

  _onConnection: (socket) ~>
    if @client? then socket.end!
    else @_setupConnection socket

  _setupConnection: (socket) ->
    (@client = socket).on \close, ~> @client = null
    if not @connection?
      @connection = new Connection
      @connection.connect @port, @host

    functions =
      send: (args) ->
        console.log "SEEEEEEEEEEEEEND"
        @connection.send ...args
      close: ~>
        @close!
    onRemote = (remote) ~>
      @connection.on \message, remote~incoming

    @client
      .pipe (dnode functions, onRemote)
      .pipe @client


    # @server.on \aborted, ->
    #   console.log 'Server already running'
    #   process.exit 0

    # process.on \SIGINT, @~close
