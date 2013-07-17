should = it
pathToModule = modulePath \connection, \PersistentConnectionClient

describe 'PersistentConnectionClient', ->

  describe 'callback API', ->
    should "expose callbacks via dnode", ->
      client = new @ConnectionClient spy.socket
      spy.dnode.should.have.been.calledOnce
      spy.dnode.args[0][0].should.have.keys [
        \connect
        \message
        \init
      ]

    describe ".message()", ->
      should "emit 'message'", (done) ->
        client = new @ConnectionClient spy.socket
        message = {command: 'WELCOME'}
        client.on \message, (msg) ->
          expect msg .to.equal message
          done!
        spy.dnode.args[0][0].message message

    describe ".connect()", ->
      should "emit 'connect'", (done) ->
        client = new @ConnectionClient spy.socket
        client.on \connect, done
        spy.dnode.args[0][0].connect!

    describe ".init()", ->
      should "emit 'init'", (done) ->
        client = new @ConnectionClient spy.socket
        client.on \init, done
        spy.dnode.args[0][0].init!

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


