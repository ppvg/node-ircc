should = it
pathToModule = modulePath \connection, \PersistentConnectionServer

describe 'PersistentConnectionServer', ->

  should 'create SingletonServer', ->
    pcs = new @PersistentConnectionServer
    spy.SingletonServer.should.have.been.calledOnce
    spy.SingletonServer.should.have.been.calledWithNew
    pcs.server.should.equal spy.server

  shouldForward = (event) ->
    (done) ->
      callback = catchCallback spy.server, \on, event
      pcs = new @PersistentConnectionServer
      pcs.on event, done
      callback!

  should "forward 'listening' events", shouldForward \listening
  should "forward 'superfluous' events", shouldForward \superfluous
  should "forward 'error' events", shouldForward \error
  should "forward 'close' events", shouldForward \close

  should "forward 'listening' events", (done) ->
    listening = catchCallback spy.server, \on, \listening
    pcs = new @PersistentConnectionServer
    pcs.on \listening, done
    listening!

  describe 'when a client connects', ->
    should 'expose API via dnode', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      triggerConnection spy.socket
      spy.dnode.args[0][0].should.be.an.object
      spy.dnode.args[0][0].should.have.keys <[connect close send]>

    should 'pipe dnode object to socket', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      triggerConnection spy.socket
      spy.socket.pipe.should.have.been.calledOnce
      spy.socket.pipe.should.have.been.calledWith spy.d
      spy.d.pipe.should.have.been.calledOnce
      spy.d.pipe.should.have.been.calledWith spy.socket

  describe '#listen()', ->
    should 'start the server', ->
      pcs = new @PersistentConnectionServer
      pcs.listen \ircc.sock
      spy.server.listen.should.have.been.calledOnce
      spy.server.listen.should.have.been.calledWith \ircc.sock

  describe '#connect()', ->
    should 'create Connection unless it already exists', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      triggerConnection spy.socket
      spy.dnode.args[0][0].connect 6667, \irc.example.com
      spy.Connection.should.have.been.calledOnce
      spy.connection.connect.should.have.been.calledOnce
      spy.connection.connect.should.have.been.calledWith 6667, \irc.example.com
      pcs.connection.should.equal spy.connection

    should 'not create Connection if it already exists', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      expect pcs.connection .to.be.null
      triggerConnection spy.socket
      spy.dnode.args[0][0].connect!
      spy.Connection.should.have.been.calledOnce

      spy.Connection.reset!
      spy.dnode.args[0][0].connect!
      spy.Connection.should.not.have.been.called

    should "emit 'message' event on incoming message from connection", (done) ->
      triggerConnection = catchCallback spy.server, \on, \connection
      triggerMessage = catchCallback spy.connection, \on, \message
      dummyMessage = { command: \WELCOME }
      pcs = new @PersistentConnectionServer
      pcs.on \message, (message) ->
        message.should.equal dummyMessage
        done!
      triggerConnection spy.socket
      spy.dnode.args[0][0].connect 6667, \irc.example.com
      triggerMessage dummyMessage

    should "emit 'connect' event when connection is made", (done) ->
      triggerConnection = catchCallback spy.server, \on, \connection
      triggerConnected = catchCallback spy.connection, \on, \connect
      spy.d.on.yields spy.remote
      pcs = new @PersistentConnectionServer
      pcs.on \connect, done
      triggerConnection spy.socket
      spy.dnode.args[0][0].connect 6667, \irc.example.com
      triggerConnected!

  describe '#send()', ->
    should 'proxy to connection.send()', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      pcs.connect 6667, \irc.example.com
      pcs.send \one, \two, 3
      spy.connection.send.should.have.been.calledOnce
      spy.connection.send.should.have.been.calledWithExactly \one, \two, 3

    should 'fail silently if connection is not open', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      (-> pcs.send \one, \two, 3).should.not.throw!
      spy.connection.send.should.not.have.been.called

  describe '#close()', ->
    should 'close the Connection', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      pcs.connect 6667, \irc.example.com
      pcs.close!
      spy.connection.close.should.have.been.calledOnce

    should 'stop accepting client connections', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      pcs.connect 6667, \irc.example.com
      pcs.close!
      spy.server.close.should.have.been.calledOnce

    should 'close gracefully even if connection is not open', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      pcs.close!
      spy.server.close.should.have.been.calledOnce

  describe 'client-server API', ->
    shouldProxy = (method) ->
      triggerConnection = catchCallback spy.server, \on, \connection
      pcs = new @PersistentConnectionServer
      pcs[method] = sinon.spy!
      triggerConnection spy.socket
      dummyArg = {}
      spy.dnode.args[0][0][method] dummyArg
      pcs[method].should.have.been.calledOnce
      pcs[method].should.have.been.calledWithExactly dummyArg

    should 'proxy .connect() to #connect()', ->
      shouldProxy.call @, \connect

    should 'proxy .send() to #send()', ->
      shouldProxy.call @, \send

    should 'proxy .close() to #close()', ->
      shouldProxy.call @, \close

    should 'send incoming messages to the client', ->
      triggerConnection = catchCallback spy.server, \on, \connection
      spy.d.on.yields spy.remote
      pcs = new @PersistentConnectionServer
      incomingMessage = catchCallback pcs, \on, \message
      triggerConnection spy.socket
      dummyMessage = { command: \WELCOME }
      incomingMessage dummyMessage
      spy.remote.message.should.have.been.calledOnce
      spy.remote.message.should.have.been.calledWith dummyMessage

    should "inform client of 'connect' events", (done) ->
      triggerConnection = catchCallback spy.server, \on, \connection
      spy.d.on.yields spy.remote
      pcs = new @PersistentConnectionServer
      pcs.on \connect, ->
        setImmediate ->
          spy.remote.connect.should.have.been.calledOnce
          done!
      triggerConnection spy.socket
      pcs.emit \connect

    should "call 'connect' on client when connection already existed", ->
      triggerConnection = catchCallback spy.server, \on, \connection
      spy.d.on.yields spy.remote
      pcs = new @PersistentConnectionServer
      pcs.connection = spy.connection
      triggerConnection spy.socket
      spy.remote.connect.should.have.been.calledOnce

    should "call 'init' on client if not already connected", ->
      triggerConnection = catchCallback spy.server, \on, \connection
      spy.d.on.yields spy.remote
      pcs = new @PersistentConnectionServer
      triggerConnection spy.socket
      spy.remote.init.should.have.been.calledOnce

    should "not call 'init' on client if already connected", ->
      triggerConnection = catchCallback spy.server, \on, \connection
      spy.d.on.yields spy.remote
      pcs = new @PersistentConnectionServer
      pcs.connection = spy.connection
      triggerConnection spy.socket
      spy.remote.init.should.not.have.been.called

  beforeEach ->
    [s.reset! for i, s of spy when s.reset?]
    [s.resetBehavior! for i, s of spy when s.resetBehavior?]
    spy.Connection.returns spy.connection
    spy.SingletonServer.returns spy.server
    spy.connection.connect = sinon.spy!
    spy.connection.send = sinon.spy!
    spy.connection.close = sinon.spy!
    spy.connection.on = sinon.spy!
    spy.server.listen = sinon.spy!
    spy.server.on = sinon.spy!
    spy.server.close = sinon.spy!
    spy.socket.pipe = sinon.stub!
    spy.socket.pipe.returns spy.d
    spy.dnode.returns spy.d
    spy.d.pipe = sinon.spy!
    spy.d.on = sinon.stub!
    spy.remote.message = sinon.spy!
    spy.remote.connect = sinon.spy!
    spy.remote.init = sinon.spy!

  before ->
    mockery.enable!
    mockery.registerAllowables [\events, pathToModule], true
    mockery.registerMock \dnode, spy.dnode
    mockery.registerMock \./Connection, spy.Connection
    mockery.registerMock \./SingletonServer, spy.SingletonServer
    @PersistentConnectionServer = require pathToModule

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