require! dnode
require! \./Connection
require! \./createUnixServer

# TODO write unit tests
# TODO refactor to remove references to `process` (move to command.ls)

module.exports = class ConnectionServer
  (@port, @host, @path) ->
    @server = createUnixServer @path
    @server.maxConnections = 1
    @_conn = null
    @client = null

    @server.on \connection, (socket) ~>
      if @client?
        socket.end!
      else
        @client = socket
        @client.on \close, ~> @client = null
        @setupDnode!

    @server.on \aborted, ->
      console.log 'Server already running'
      process.exit 0

    process.on \SIGINT, this~close

  connection: ->
    if not @_conn?
      @_conn = new Connection
      @_conn.connect @port, @host
    @_conn

  setupDnode: ->
    conn = @connection!
    d = dnode {
      send: (args) ->
        conn.send ...args
      close: ~>
        @close!
    }
    d.on \remote, (remote) ->
      conn.on \message, remote~incoming
    @client
      .pipe d
      .pipe @client

  start: ->
    @server.start!

  close: ->
    if @client? then @client.end!
    if @_conn? then @_conn.close!
    @server.close!
