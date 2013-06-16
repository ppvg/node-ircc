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
  var triggerReadable

  # Helper functions:

  defaultConnection = ->
    connection = new Connection nickname: \TestBot
    connection.connect 6667 \irc.example.com
    connection

  serializerExpect = (expected, callback) ->
    if typeof! expected isnt \Array then expected = [expected]
    # Reset the serializer.write spy
    spy.ss.write.reset!
    # Run the code
    callback!
    # Check the result
    if spy.ss.write.callCount isnt expected.length
      throw new Error "Expected serialize.write to be called #{expected.length} time(s)"
    for expectation, i in expected
      actual = spy.ss.write.args[i][0]
      actual.should.eql expectation

  beforeEach ->
    for k, s of ctorSpy then s.reset!
    triggerReadable := ->
      throw new Error '@parser.on not called yet!'
    spy.socket = {}
    for func in [\pipe, \unpipe, \connect, \destroy, \end]
      spy.socket[func] = sinon.spy!
    spy.ss = {}
    for func in [\pipe, \unpipe, \write]
      spy.ss[func] = sinon.spy!
    spy.ps :=
      on: (event, cb) ->
        if event is \readable
          triggerReadable := cb

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
      connection = defaultConnection!
      ctorSpy.SS.should.have.been.called
      ctorSpy.PS.should.have.been.called
      connection.serializer.should.equal spy.ss
      connection.parser.should.equal spy.ps

    should 'open a Socket using the given port and host', ->
      connection = defaultConnection!
      createConnection = ctorSpy.Socket
      createConnection.should.have.been.calledOnce
      createConnection.should.have.been.calledWith 6667, \irc.example.com
      connection.socket.should.equal spy.socket

    should 'pipe the Socket into the ParserStream', ->
      pipe = spy.socket.pipe = sinon.spy!
      connection = defaultConnection!
      pipe.should.have.been.calledWith spy.ps

    should 'pipe the SerializerStream into the Socket', ->
      pipe = spy.ss.pipe = sinon.spy!
      connection = defaultConnection!
      pipe.should.have.been.calledWith spy.socket

    should 'send NICK and USER commands to the server', ->
      connection = new Connection {
        nickname: \TestBot,
        username: \testbot,
        realname: 'The TestBot'
      }
      expected =
        * { command: \NICK, parameters: [\TestBot] }
        * { command: \USER, parameters: [\testbot, 0, 0, 'The TestBot'] }
      serializerExpect expected, ->
        connection.connect 6667 \irc.example.com

    should 'throw error if trying to connect twice', ->
      connection = defaultConnection!
      (-> connection.connect 6667).should.throw 'Already connected'

  should 'emit "raw" event on incoming messages from the ParserStream', (done) ->
    connection = defaultConnection!
    connection.on \raw, (message) ->
      message.command.should.equal 'QUIT'
      done!
    spy.ps.read = returnOnce { command: 'QUIT', type: 'command' }
    triggerReadable!

  should 'emit events for message types', (done) ->
    connection = defaultConnection!
    called = false
    callback = (message) ->
      message.command.should.equal \KICK
      if called then done!
      else called := true
    connection.on \KICK, callback
    connection.on \kick, callback
    spy.ps.read = returnOnce { command: 'KICK', type: 'command' }
    triggerReadable!

  describe '#disconnect', ->
    should 'send QUIT command', ->
      connection = defaultConnection!
      spy.ss.write.should.have.been.calledTwice
      QUIT = { command: 'QUIT' }
      serializerExpect QUIT, ->
        connection.disconnect!

    should 'accept message for QUIT command', ->
      connection = defaultConnection!
      spy.ss.write.should.have.been.calledTwice
      QUIT = { command:\QUIT, parameters: [\Buh-Bai!] }
      serializerExpect QUIT, ->
        connection.disconnect \Buh-Bai!

    should 'wait for confirmation from the server (ERROR command)', (done) ->
      connection = defaultConnection!
      connection.disconnect!
      ERRORreceived = false
      connection.on \disconnected, ->
        ERRORreceived.should.be.false
        done!
      setImmediate ->
        spy.ps.read = returnOnce { command: \ERROR }
        triggerReadable!
        ERRORreceived := true

    should 'cleanly disconnect socket', ->
      connection = defaultConnection!
      connection.disconnect!
      spy.ps.read = returnOnce { command: \ERROR }
      triggerReadable!
      ser = connection.serializer; sock = connection.socket
      ser.unpipe.should.have.been.calledWith connection.socket
      sock.unpipe.should.have.been.calledWith connection.parser
      sock.end.should.have.been.called

    should 'throw error on invalid disconnect message', ->
      connection = defaultConnection!
      (-> connection.disconnect {cookies: 'are not a valid quit message'})
        .should.throw 'Invalid QUIT message'

    should 'emit "disconnected" event', (done) ->
      connection = defaultConnection!
      connection.on \disconnected, -> done!
      connection.on \error, ->
        throw new Error 'Should not emit "error"...'
      connection.disconnect!
      # Servers confirm QUIT by responding with ERROR:
      spy.ps.read = returnOnce { command: \ERROR }
      triggerReadable!

    should 'make it possible to connect again', (done) ->
      connection = defaultConnection!
      connection.disconnect!
      spy.ps.read = returnOnce { command: \ERROR }
      triggerReadable!
      setImmediate ->
        (-> connection.connect 6667).should.not.throw Error
        done!

  should 'emit "error" event on unexpected disconnect', (done) ->
    connection = defaultConnection!
    connection.on \error, -> done!
    connection.on \disconnected, ->
      throw new Error 'Should not emit "disconnected"...'
    spy.ps.read = returnOnce { command: \ERROR }
    triggerReadable!

  should 'emit "error" event on receiving message of type ERR_', (done) ->
    connection = defaultConnection!
    connection.on \error, -> done!
    spy.ps.read = returnOnce { command: \CHANNELISFULL, type: \error }
    triggerReadable!

  describe '#send', ->
    should 'send command through Serializer', ->
      connection = defaultConnection!
      expected = {command: \PRIVMSG}
      serializerExpect expected, ->
        connection.send \PRIVMSG

    should 'accept optional Array of parameters', ->
      connection = defaultConnection!
      expected = {command: \PRIVMSG, parameters: [\#channel \COOKIES!]}
      serializerExpect expected, ->
        connection.send \PRIVMSG, [\#channel \COOKIES!]

    should 'accept variable number of arguments as parameters', ->
      connection = defaultConnection!
      expected = {command: \PET, parameters: [\the \Alot \of \parameters]}
      serializerExpect expected, ->
        connection.send \PET, \the, \Alot, \of, \parameters
      expected = {command: \NUMS, parameters: [\are, \fine, \42, \9001]}
      serializerExpect expected, ->
        connection.send \NUMS, \are, \fine, 42, 9001

    should 'accept raw message object as parameter', ->
      # Don't know yet if this is a good idea.
      connection = defaultConnection!
      expected = {command: \PRIVMSG, parameters: [\#channel \COOKIES!]}
      serializerExpect expected, ->
        connection.send expected

    should 'throw error on invalid arguments', ->
      connection = defaultConnection!
      (-> connection.send [\TWO \COMMANDS])
        .should.throw 'Invalid command'
      (-> connection.send {commmmmadn: \MISSPELL})
        .should.throw 'Invalid command'


  should.skip 'handle TLS connection', ->
  should.skip 'connect to password-protected servers', ->
  should.skip 'emit "connected" event?', ->

function returnOnce value
  called = false
  ->
    if not called
      called := true
      value
    else
      null
