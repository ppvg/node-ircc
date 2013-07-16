should = it
pathToModule = modulePath \connection, \PersistentConnectionClient

describe 'PersistentConnectionClient', ->

  should "create dnode instance with 'incoming' method", ->
    client = new @ConnectionClient spy.socket
    spy.dnode.should.have.been.calledOnce
    spy.dnode.args[0][0].should.have.key \incoming
    spy.dnode.args[0][0].incoming.should.be.a \function

  should "emit 'message' when the 'incoming' method is called", (done) ->
    client = new @ConnectionClient spy.socket
    message = {command: 'WELCOME'}
    client.on \message, (msg) ->
      expect msg .to.equal message
      done!
    spy.dnode.args[0][0].incoming message

  shouldProxyToDnode = (func) ->
    ->
      should 'throw error if not fully connected', ->
        client = new @ConnectionClient spy.socket
        (-> client[func]!).should.throw 'Not connected'

      should "proxy to remote.#{func}()", ->
        spy.d.on.yields spy.remote
        client = new @ConnectionClient spy.socket
        (-> client[func] \dummy \args).should.not.throw!
        spy.remote[func].should.have.been.calledOnce
        spy.remote[func].should.have.been.calledWith \dummy \args

  describe '#connect()', shouldProxyToDnode \connect
  describe '#close()', shouldProxyToDnode \close
  describe '#send()', shouldProxyToDnode \send

  should "emit 'connect' when dnode emits 'remote'", (done) ->
    onRemote = catchCallback spy.d, \on, \remote
    client = new @ConnectionClient spy.socket
    client.on \connect, done
    onRemote spy.remote

  should "accept optional callback which is called on 'connect'", ->
    onRemote = sinon.spy!
    client = new @ConnectionClient spy.socket, onRemote
    client.emit \connect
    onRemote.should.have.been.calledOnce

  should 'pipe together socket and dnode', ->
    client = new @ConnectionClient spy.socket
    spy.socket.pipe.should.have.been.calledOnce
    spy.d.pipe.should.have.been.calledOnce
    spy.socket.pipe.args[0][0].should.equal spy.d
    spy.d.pipe.args[0][0].should.equal spy.socket

  beforeEach ->
    [s.reset! for k, s of spy when s.reset?]
    spy.d.on = sinon.stub!
    spy.d.pipe = sinon.stub!
    spy.socket.pipe = sinon.stub!
    for func in <[connect close send]>
      spy.remote[func] = sinon.spy!

    spy.dnode.returns spy.d
    spy.socket.pipe.returns spy.d
    spy.d.pipe.returns spy.socket

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
    socket: {}
    remote: {}
    d: {}


