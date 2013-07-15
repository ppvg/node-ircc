require! \dnode
require! \./Connection
require! \./SingletonServer

module.exports = class PersistentConnectionServer
  (@port, @host, @path) ->
    @server = new SingletonServer @path
    @server.on \connection, @_onConnection
    @connection = null

  start: ->
    @server.start!

  _onConnection: (socket) ~>
    if not @connection?
      @connection = new Connection
      @connection.connect @port, @host

    api =
      send: @connection~send
      close: @connection~close
    onRemote = (remote) ~>
      @connection.on \message, remote~incoming

    socket
      .pipe dnode api, onRemote
      .pipe socket