should = it
pathToModule = modulePath \connection, \SingletonServer

describe 'SingletonServer', ->

  should 'create a net.Server', ->
    ss = new @SingletonServer
    spy.createServer.should.have.been.calledOnce
    ss.server.should.equal spy.server

  should "forward 'listening' events", (done) ->
    listening = catchCallback spy.server, \on, \listening
    ss = new @SingletonServer
    ss.on \listening, done
    listening!

  should "forward 'close' events", (done) ->
    close = catchCallback spy.server, \on, \close
    ss = new @SingletonServer
    ss.on \close, done
    close!

  describe 'on client connection', ->
    should "emit 'connection' event", (done) ->
      incomingConnection = catchCallback spy.server, \on, \connection
      ss = new @SingletonServer
      expect ss.client .to.be.null
      ss.on \connection, (socket) ->
        socket.should.equal spy.socket
        done!
      incomingConnection spy.socket

    should 'accept max 1 connection', ->
      incomingConnection = catchCallback spy.server, \on, \connection
      ss = new @SingletonServer
      incomingConnection spy.socket
      spy.socket.end.should.not.have.been.called
      incomingConnection spy.socket
      spy.socket.end.should.have.been.calledOnce

    should 'ignore errors from superfluous connections', ->
      incomingConnection = catchCallback spy.server, \on, \connection
      ss = new @SingletonServer
      incomingConnection spy.socket
      # second connection will emit error:
      connectionError = catchCallback spy.socket, \on, \error
      incomingConnection spy.socket
      connectionError! # boom!
      # nothing should happen
      ss.client.should.equal spy.socket

  describe 'on client disconnection', ->
    should 'prepare for new connection', ->
      incomingConnection = catchCallback spy.server, \on, \connection
      closingConnection = catchCallback spy.socket, \on, \close
      ss = new @SingletonServer
      incomingConnection spy.socket
      closingConnection!
      expect ss.client .to.be.null

  describe 'on client error', ->
    should 'prepare for new connection', ->
      incomingConnection = catchCallback spy.server, \on, \connection
      connectionError = catchCallback spy.socket, \on, \error
      ss = new @SingletonServer
      incomingConnection spy.socket
      connectionError!
      expect ss.client .to.be.null

  describe '#listen()', ->
    should 'start listening on given unix socket', ->
      server = new @SingletonServer
      server.listen \./server.sock
      spy.server.listen.should.have.been.calledOnce
      spy.server.listen.should.have.been.calledWith \./server.sock

    describe 'if address already in use', ->
      should "emit 'superfluous' if server already running", (done) ->
        yield_EADDRINUSE!
        connectSuccesfully = catchCallback spy.socket, \on, \connect
        server = new @SingletonServer
        server.on \superfluous, ->
          spy.socket.end.should.have.been.calledOnce
          done!
        setImmediate ->
          server.listen \./server.sock
          connectSuccesfully!

      should 'remove socket file if server not running', (done) ->
        yield_EADDRINUSE!
        yield_ECONNREFUSED!
        server = new @SingletonServer
        server.listen \./server.sock
        # double setImmediate because of the 2 error steps
        setImmediate -> setImmediate ->
          spy.server.listen.should.have.been.calledTwice
          spy.fs.unlink.should.have.been.calledOnce
          spy.fs.unlink.should.have.been.calledWith \./server.sock
          done!

  beforeEach ->
    [s.reset! for i, s of spy when s.reset?]
    [s.resetBehavior! for i, s of spy when s.resetBehavior?]
    spy.createServer.returns spy.server
    spy.createConnection.returns spy.socket
    spy.server.listen = sinon.spy!
    spy.server.emit = sinon.spy!
    spy.server.on = sinon.spy!
    spy.socket.emit = sinon.spy!
    spy.socket.end = sinon.spy!
    spy.socket.on = sinon.spy!
    spy.fs.unlink = sinon.spy!

  before ->
    mockery.enable!
    mockery.registerAllowables [\events pathToModule], true
    mockery.registerMock \net, { createServer: spy.createServer, createConnection: spy.createConnection }
    mockery.registerMock \fs, spy.fs

    @SingletonServer = require pathToModule

  after ->
    mockery.deregisterAll!
    mockery.disable!

  spy =
    createServer: sinon.stub!
    createConnection: sinon.stub!
    server: {}
    socket: {}
    fs: {}

  yield_EADDRINUSE = ->
   spy.server.on = (type, callback) ->
      if type is \error then setImmediate ->
        callback { code: \EADDRINUSE }

  yield_ECONNREFUSED = ->
   spy.socket.on = (type, callback) ->
      if type is \error then setImmediate ->
        callback { code: \ECONNREFUSED }