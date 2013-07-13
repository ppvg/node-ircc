should = it

var createUnixServer
pathToModule = path.join libPath, \createUnixServer

spy =
  createServer: sinon.stub!
  createConnection: sinon.stub!
  Server: sinon.spy!
  Socket: sinon.spy!
  fs:
    unlink: sinon.spy!

spy.Server.listen = sinon.spy!
spy.Server.emit = sinon.spy!
spy.Server.on = sinon.stub!
spy.Socket.on = sinon.stub!

yieldEADDRINUSE = -> spy.Server.on.yields code: \EADDRINUSE
yieldECONNREFUSED = -> spy.Socket.on.yields code: \ECONNREFUSED
yieldConnection = -> spy.createConnection.yields!

before ->
  mockery.enable!
  mockery.registerAllowable pathToModule, true
  mockery.registerMock \net, createServer: spy.createServer, createConnection: spy.createConnection
  mockery.registerMock \fs, spy.fs
  createUnixServer := require pathToModule

after ->
  mockery.deregisterAll!
  mockery.disable!

describe 'createUnixServer', ->

  beforeEach ->
    [s.reset! for i, s of spy when s.reset?]
    spy.fs.unlink.reset!
    spy.Server.listen.reset!
    spy.Server.emit.reset!
    spy.Server.on.reset!
    spy.Server.on.resetBehavior!
    spy.Socket.on.reset!
    spy.Socket.on.resetBehavior!
    spy.createConnection.resetBehavior!
    spy.createServer.returns spy.Server
    spy.createConnection.returns spy.Socket

  should 'create a net.Server', ->
    server = createUnixServer \./server.sock
    spy.createServer.should.have.been.calledOnce
    server.should.equal spy.Server

  should 'attach connectionListener to Server', ->
    listener = (socket) -> void
    server = createUnixServer \./server.sock listener
    spy.createServer.should.have.been.calledWith listener

  describe 'server.start()', ->
    should 'start listening to the given unix socket', ->
      server = createUnixServer \./server.sock
      server.start!
      spy.Server.listen.should.have.been.calledOnce
      spy.Server.listen.should.have.been.calledWith \./server.sock

  should 'listen for EADDRINUSE', ->
    server = createUnixServer \./server.sock
    spy.Server.on.should.have.been.calledOnce
    spy.Server.on.should.have.been.calledWith \error

  describe 'on EADDRINUSE', ->
    should 'try if a server is already running', ->
      yieldEADDRINUSE!
      server = createUnixServer \./server.sock
      spy.createConnection.should.have.been.calledOnce
      spy.createConnection.should.have.been.calledWith \./server.sock
      spy.Socket.on.should.have.been.calledOnce
      spy.Socket.on.should.have.been.calledWith \error

    should "emit 'aborted' if server already running", ->
      yieldEADDRINUSE!
      yieldConnection!
      server = createUnixServer \./server.sock
      spy.Server.emit.should.have.been.calledOnce
      spy.Server.emit.should.have.been.calledWith \aborted

    should 'remove socket file if server is not running', ->
      yieldEADDRINUSE!
      yieldECONNREFUSED!
      server = createUnixServer \./server.sock
      server.start!
      spy.fs.unlink.should.have.been.calledOnce
      spy.fs.unlink.should.have.been.calledWith \./server.sock
      spy.Server.listen.should.have.been.calledTwice
