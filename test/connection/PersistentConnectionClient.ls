should = it
pathToModule = modulePath \connection, \PersistentConnectionClient

describe 'PersistentConnectionClient', ->

  should "create dnode instance with 'incoming' method", ->
    client = new @ConnectionClient spy.socket
    spy.dnode.should.have.been.calledOnce
    spy.dnode.args[0][0].should.have.key \incoming
    spy.dnode.args[0][0].incoming.should.be.a \function

  should "emit 'message' when the 'incoming' method is called", ->
    client = new @ConnectionClient spy.socket
    message = {command: 'WELCOME'}
    client.emit = sinon.spy!
    spy.dnode.args[0][0].incoming message
    client.emit.should.have.been.calledOnce
    client.emit.should.have.been.calledWithExactly \message, message

  should "emit 'remote' when dnode emits 'remote'", ->
    client = new @ConnectionClient spy.socket
    spy.d.on.should.have.been.calledOnce
    spy.d.on.args[0][0].should.equal \remote
    spy.d.on.args[0][1].should.be.a \function
    client.emit = sinon.spy!
    remoteSpy = sinon.spy!
    spy.d.on.args[0][1] remoteSpy
    client.emit.should.have.been.calledOnce
    client.emit.should.have.been.calledWithExactly \remote, remoteSpy

  should "accept optional callback which is called on 'remote'", ->
    onRemote = sinon.spy!
    client = new @ConnectionClient spy.socket, onRemote
    client.emit = sinon.spy!
    remoteSpy = sinon.spy!
    spy.d.on.args[0][1] remoteSpy
    onRemote.should.have.been.calledOnce
    onRemote.should.have.been.calledWithExactly remoteSpy

  should 'pipe socket and dnode and back', ->
    client = new @ConnectionClient spy.socket
    spy.socket.pipe.should.have.been.calledOnce
    spy.d.pipe.should.have.been.calledOnce
    spy.socket.pipe.args[0][0].should.equal spy.d
    spy.d.pipe.args[0][0].should.equal spy.socket

  beforeEach ->
    [s.reset! for k, s of spy]
    [spy.d[s].reset! for s in [\on \pipe]]
    spy.socket.pipe.reset!

  before ->
    mockery.enable!
    mockery.registerMock \dnode, spy.dnode
    mockery.registerAllowables [pathToModule, \events], true
    @ConnectionClient = require pathToModule

  after ->
    mockery.deregisterAll!
    mockery.disable!

  spy =
    dnode: sinon.stub!
    socket: sinon.stub!
    d: sinon.stub!

  spy.d.on = sinon.stub!
  spy.d.pipe = sinon.stub!
  spy.socket.pipe = sinon.stub!

  spy.dnode.returns spy.d
  spy.socket.pipe.returns spy.d
  spy.d.pipe.returns spy.socket
