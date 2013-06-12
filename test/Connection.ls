should = it

var Connection
pathToConnection = path.join libPath, \Connection

ctorSpy =
  SS: sinon.spy!
  PS: sinon.spy!
  Socket: sinon.spy!
spy = {}

/* Creates a mock constructor, which calls the ctorSpy and returns the instance spy. */
createMock = (name) ->
  (...args)->
    ctorSpy[name] ...args
    spy[name.toLowerCase!]

before ->
  mockery.enable!
  mockery.registerAllowables [\./codes \events]
  mockery.registerAllowable pathToConnection, true
  mockery.registerMock \./SerializerStream, createMock \SS
  mockery.registerMock \./ParserStream, createMock \PS
  mockery.registerMock \net, { createConnection: createMock \Socket }
  Connection := require pathToConnection

after ->
  mockery.deregisterAll!
  mockery.disable!

describe 'Connection', ->
  beforeEach ->
    for k, s of ctorSpy then s.reset!
    spy.ss := {pipe:sinon.spy!, write:sinon.spy!}
    spy.ps := {on:sinon.stub!}
    spy.socket := {pipe:sinon.spy!, connect:sinon.spy!}

  should 'idle until #connect is called', (done) ->
    connection = new Connection
    setImmediate ->
      expect connection.socket .to.not.exist
      done!

  should 'use nickname as default for username and realname', ->
    connection = new Connection nickname: \TestBot
    connection.nickname.should.equal \TestBot
    connection.username.should.equal \TestBot
    connection.realname.should.equal \TestBot

  describe '#connect', ->
    should 'accept object with socket options', ->
      connection = new Connection nickname: \TestBot
      connection.connect { host: \irc.example.com, port: 6667 }
      connection.host.should.equal \irc.example.com
      connection.port.should.equal 6667

    should 'accept separate host and port arguments', ->
      connection = new Connection nickname: \TestBot
      connection.connect 6667, \irc.example.com
      connection.port.should.equal 6667
      connection.host.should.equal \irc.example.com

    should 'default host to "localhost" (if port is supplied)', ->
      connection = new Connection nickname: \TestBot
      connection.connect 6667
      connection.host.should.equal \localhost
      connection = new Connection nickname: \TestBot
      connection.connect { port: 6667 }
      connection.host.should.equal \localhost

    should 'default port to 6667 (if host is supplied)', ->
      connection = new Connection nickname: \TestBot
      connection.connect \irc.example.com
      connection.port.should.equal 6667
      connection = new Connection nickname: \TestBot
      connection.connect { host: \irc.example.com }
      connection.port.should.equal 6667

    should 'throw error when called without or with invalid options', ->
      connection = new Connection nickname: \TestBot
      connection.~connect
        .should.throw 'Invalid socket options'
      (-> connection.connect (->))
        .should.throw 'Invalid socket options'
      (-> connection.connect unrelated: 'object')
        .should.throw 'Invalid socket options'
      (-> connection.connect host: 6667)
        .should.throw 'Invalid socket options'
      (-> connection.connect port: 'COOKIES!')
        .should.throw 'Invalid socket options'

    should 'create a new ParserStream and SerializerStream', ->
      connection = new Connection nickname: \TestBot
      connection.connect 6667 \irc.example.com
      ctorSpy.SS.should.have.been.called
      ctorSpy.PS.should.have.been.called
      connection.serializer.should.equal spy.ss
      connection.parser.should.equal spy.ps

    should 'open a Socket using the given port and host', ->
      connection = new Connection nickname: \TestBot
      connection.connect 6667 \irc.example.com
      createConnection = ctorSpy.Socket
      createConnection.should.have.been.calledOnce
      createConnection.should.have.been.calledWith 6667, \irc.example.com
      connection.socket.should.equal spy.socket

    should 'pipe the Socket into the ParserStream', ->
      pipe = spy.socket.pipe = sinon.spy!
      connection = new Connection nickname: \TestBot
      connection.connect 6667, \irc.example.com
      pipe.should.have.been.calledWith spy.ps

    should 'pipe the SerializerStream into the Socket', ->
      pipe = spy.ss.pipe = sinon.spy!
      connection = new Connection nickname: \TestBot
      connection.connect 6667, \irc.example.com
      pipe.should.have.been.calledWith spy.socket

    should 'send NICK and USER commands to the server', ->
      write = spy.ss.write
      connection = new Connection nickname: \TestBot, username: \testbot, realname: 'The TestBot'
      connection.connect 6667, \irc.example.com
      write.should.have.been.calledTwice
      write.args[0][0].should.eql command: \NICK, parameters: [\TestBot]
      write.args[1][0].should.eql command: \USER, parameters: [\testbot, 0, 0, 'The TestBot']

  should 'emit "raw" event on incoming messages from the ParserStream', (done) ->
    spy.ps.on.yields!
    spy.ps.read = returnOnce { command: 'QUIT' }
    connection = new Connection nickname: \TestBot
    connection.on \raw, (message) ->
      message.command.should.equal 'QUIT'
      done!
    connection.connect 6667 \irc.example.com

  should 'emit events for message types', (done) ->
    spy.ps.on.yields!
    spy.ps.read = returnOnce { command: 'KICK' }
    connection = new Connection nickname: \TestBot
    connection.on \welcome, (message) ->
      expect message.command .to.not.exist
      done!
    connection.connect 6667 \irc.example.com
    done!


function returnOnce value
  called = false
  ->
    if not called
      called := true
      value
    else
      null
