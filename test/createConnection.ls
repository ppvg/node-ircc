i = it
pathToModule = modulePath \createConnection

describe \createConnection, ->

  i 'create a new Connection', ->
    connection = @createConnection 6667, \irc.example.com
    ctorSpy.should.have.been.calledOnce
    expect connection .to.equal instanceSpy

  i 'start connection with the given port and host', ->
    connection = @createConnection 6667, \irc.example.com
    instanceSpy.connect.should.have.been.calledOnce

  i 'call connectListener when connection is made', ->
    withoutCallback = @createConnection 6667, \irc.example.com
    instanceSpy.on.should.not.have.been.called
    mockCallback = -> void
    withCallback = @createConnection 6667, \irc.example.com, mockCallback
    instanceSpy.on.should.have.been.calledOnce
    instanceSpy.on.should.have.been.calledWith \connect, mockCallback

  beforeEach ->
    ctorSpy.reset!
    ctorSpy.resetBehavior!
    ctorSpy.returns instanceSpy
    instanceSpy.connect = sinon.spy!
    instanceSpy.on = sinon.spy!

  before ->
    mockery.enable();
    mockery.registerMock \./Connection, ctorSpy
    mockery.registerAllowable pathToModule, true
    @createConnection = require pathToModule

  after ->
    mockery.deregisterAll();
    mockery.disable();

  ctorSpy = sinon.stub!
  instanceSpy = sinon.spy!
