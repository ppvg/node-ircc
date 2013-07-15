should = it
pathToModule = modulePath \connection, \PersistentConnectionServer

describe 'PersistentConnectionServer', ->

  should 'create SingletonServer', ->
    pcs = @defaultPCS!
    spy.SingletonServer.should.have.been.calledOnce
    spy.SingletonServer.should.have.been.calledWithNew
    pcs.server.should.equal spy.server

  describe 'when a client connects', ->
    should 'setup Connection if not yet open', ->
      connect = catchCallback spy.server, \on, \connection
      pcs = @defaultPCS!
      expect pcs.connection .to.be.null

      connect spy.socket
      spy.Connection.should.have.been.calledOnce
      spy.connection.connect.should.have.been.calledOnce
      spy.connection.connect.should.have.been.calledWith 6667, \irc.example.com
      pcs.connection.should.equal spy.connection

      spy.Connection.reset!
      connect spy.socket
      spy.Connection.should.not.have.been.called

    should 'connect socket to dnode API', ->
      connect = catchCallback spy.server, \on, \connection
      pcs = @defaultPCS!
      connect spy.socket
      spy.socket.pipe.should.have.been.calledOnce
      spy.socket.pipe.should.have.been.calledWith spy.d
      spy.d.pipe.should.have.been.calledOnce
      spy.d.pipe.should.have.been.calledWith spy.socket
      spy.dnode.args[0][0].should.be.an.object
      spy.dnode.args[0][1].should.be.a.function

  describe 'start()', ->
    should 'start the server', ->
      pcs = @defaultPCS!
      pcs.start!
      spy.server.start.should.have.been.calledOnce

  describe 'client-server API', ->
    should 'proxy send() to connection.send()', ->
      connect = catchCallback spy.server, \on, \connection
      pcs = @defaultPCS!
      connect spy.socket
      send = spy.dnode.args[0][0].send
      send \one, \two, 3
      spy.connection.send.should.have.been.calledOnce
      spy.connection.send.should.have.been.calledWithExactly \one, \two, 3

    should 'proxy close() to connection.close()', ->
      connect = catchCallback spy.server, \on, \connection
      pcs = @defaultPCS!
      connect spy.socket
      close = spy.dnode.args[0][0].close
      close!
      spy.connection.close.should.have.been.calledOnce

    should 'send incoming messages to the client', ->
      connect = catchCallback spy.server, \on, \connection
      incomingMessage = catchCallback spy.connection, \on, \message
      pcs = @defaultPCS!
      connect spy.socket
      onRemote = spy.dnode.args[0][1]
      onRemote spy.remote
      dummyMessage = { command: \WELCOME }
      incomingMessage dummyMessage
      spy.remote.incoming.should.have.been.calledOnce
      spy.remote.incoming.should.have.been.calledWith dummyMessage

  beforeEach ->
    [s.reset! for i, s of spy when s.reset?]
    [s.resetBehavior! for i, s of spy when s.resetBehavior?]
    spy.Connection.returns spy.connection
    spy.SingletonServer.returns spy.server
    spy.connection.connect = sinon.spy!
    spy.connection.send = sinon.spy!
    spy.connection.close = sinon.spy!
    spy.server.start = sinon.spy!
    spy.server.on = sinon.spy!
    spy.socket.pipe = sinon.stub!
    spy.socket.pipe.returns spy.d
    spy.dnode.returns spy.d
    spy.d.pipe = sinon.spy!
    spy.remote.incoming = sinon.spy!

  before ->
    mockery.enable!
    mockery.registerAllowable pathToModule, true
    mockery.registerMock \dnode, spy.dnode
    mockery.registerMock \./Connection, spy.Connection
    mockery.registerMock \./SingletonServer, spy.SingletonServer
    @PersistentConnectionServer = require pathToModule

    @defaultPCS = ->
      new @PersistentConnectionServer 6667 \irc.example.com \ircc.sock

  after ->
    mockery.deregisterAll!
    mockery.disable!

  spy =
    Connection: sinon.stub!
    SingletonServer: sinon.stub!
    dnode: sinon.stub!
    d: sinon.stub!
    connection: {}
    server: {}
    socket: {}
    remote: {}

  catchCallback = (obj, func, type) ->
    var callback
    obj[func] = (t, cb) ->
      if t is type then callback := cb
    ->
      if typeof callback is \function then callback ...
