should = it
pathToModule = modulePath \connection, \PersistentConnectionServer

describe 'PersistentConnectionServer', ->

  should 'create net.Server', ->
    pcs = @defaultPCS!
    spy.createServer.should.have.been.calledOnce
    pcs.server.should.equal spy.server

  describe 'when a client connects', ->
    should 'accept max 1 client connection', ->
      connectionCallback = catchCallback spy.server, \on, \connection
      pcs = @defaultPCS!
      connectionCallback spy.socket
      connectionCallback spy.socket
      pcs.server.maxConnections.should.equal 1
      spy.socket.end.should.have.been.calledOnce

    should 'accept new client after existing client disconnects', ->
      connectionCallback = catchCallback spy.server, \on, \connection
      closeCallback = catchCallback spy.socket, \on, \close
      pcs = @defaultPCS!
      connectionCallback spy.socket
      pcs.client.should.equal spy.socket
      closeCallback!
      expect(pcs.client).to.be.null

    should 'setup Connection', ->
      connectionCallback = catchCallback spy.server, \on, \connection
      pcs = @defaultPCS!
      connectionCallback spy.socket
      spy.Connection.should.have.been.calledOnce
      spy.connection.connect.should.have.been.calledOnce
      spy.connection.connect.should.have.been.calledWith 6667, \irc.example.com

    describe 'when Connection is already open', ->
      should.skip "don't create a new one"

  describe 'if address already in use', ->
    should "emit 'aborted' if server already running", ->
      yield_EADDRINUSE!
      spy.createConnection.yields!
      server = @defaultPCS!
      server.start!
      spy.server.listen.should.have.been.calledOnce
      spy.server.emit.should.have.been.calledOnce
      spy.server.emit.should.have.been.calledWith \aborted

    should 'remove socket file if server not running', ->
      yield_EADDRINUSE!
      yield_ECONNREFUSED!
      server = @defaultPCS!
      server.start!
      spy.server.listen.should.have.been.calledTwice
      spy.fs.unlink.should.have.been.calledOnce
      spy.fs.unlink.should.have.been.calledWith \ircc.sock

  describe 'server.start()', ->
    should 'start listening to given unix socket', ->
      pcs = @defaultPCS!
      pcs.start!
      spy.server.listen.should.have.been.calledOnce
      spy.server.listen.should.have.been.calledWith \ircc.sock

  describe 'the client-server protocol', ->
    should 'pipe dnode to client socket', ->
      connectionCallback = catchCallback spy.server, \on, \connection
      pcs = @defaultPCS!
      connectionCallback spy.socket
      spy.socket.pipe.should.have.been.calledOnce
      spy.socket.pipe.should.have.been.calledWith spy.d
      spy.d.pipe.should.have.been.calledOnce
      spy.d.pipe.should.have.been.calledWith spy.socket

    describe 'send()', ->
      should.skip 'send message via Connection', (done) ->
        connectionCallback = catchCallback spy.server, \on, \connection
        spy.dnode = (functions, onRemote) ->
          functions.send \beep, \boop
          spy.connection.send.should.have.been.calledOnce
          spy.connection.send.should.have.been.calledWith \beep, \boop
          done!
        pcs = @defaultPCS!
        connectionCallback spy.socket

  describe 'when Connection is closed', ->
    should.skip 'prepare for new Connection'

  beforeEach ->
    [s.reset! for i, s of spy when s.reset?]
    spy.Connection.returns spy.connection
    spy.createServer.returns spy.server
    spy.createConnection.returns spy.socket
    spy.dnode.returns spy.d
    spy.d.pipe = sinon.spy!
    spy.connection.connect = sinon.spy!
    spy.connection.send = sinon.spy!
    spy.server.listen = sinon.spy!
    spy.server.emit = sinon.spy!
    spy.server.on = sinon.spy!
    spy.socket.on = sinon.spy!
    spy.socket.emit = sinon.spy!
    spy.socket.end = sinon.spy!
    spy.socket.pipe = sinon.stub!
    spy.socket.pipe.returns spy.d
    spy.fs.unlink = sinon.spy!

  before ->
    mockery.enable!
    mockery.registerAllowable pathToModule, true
    mockery.registerMock \fs, spy.fs
    mockery.registerMock \net, createServer: spy.createServer, createConnection: spy.createConnection
    mockery.registerMock \dnode, spy.dnode
    mockery.registerMock \./Connection, spy.Connection
    @PersistentConnectionServer = require pathToModule

    @defaultPCS = ->
      new @PersistentConnectionServer 6667 \irc.example.com \ircc.sock

  after ->
    mockery.deregisterAll!
    mockery.disable!

  spy =
    Connection: sinon.stub!
    createServer: sinon.stub!
    createConnection: sinon.stub!
    dnode: sinon.stub!
    d: sinon.stub!
    connection: {}
    server: {}
    socket: {}
    fs: {}

  yield_EADDRINUSE = ->
   spy.server.on = (type, callback) ->
      if type is \error then callback { code: \EADDRINUSE }

  yield_ECONNREFUSED = ->
   spy.socket.on = (type, callback) ->
      if type is \error then callback { code: \ECONNREFUSED }

  catchCallback = (obj, func, type) ->
    var callback
    obj[func] = (t, cb) ->
      if t is type then callback := cb
    ->
      if typeof callback is \function then callback ...
