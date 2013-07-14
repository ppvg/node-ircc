should = it

var Connection
pathToConnection = path.join libPath, \connection, \Connection

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
  mockery.registerAllowables [\../protocol/codes \events]
  mockery.registerAllowable pathToConnection, true
  mockery.registerMock \../protocol/SerializerStream, createMock \SS
  mockery.registerMock \../protocol/ParserStream, createMock \PS
  mockery.registerMock \net, { createConnection: createMock \Socket }
  Connection := require pathToConnection

after ->
  mockery.deregisterAll!
  mockery.disable!

describe 'Connection', ->
  var triggerReadable

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

  connectWithDefaults = ->
    connection = new Connection
    connection.connect 6667, \irc.example.com
    connection

  beforeEach ->
    for k, s of ctorSpy then s.reset!
    triggerReadable := ->
      throw new Error '@parser.on not called yet!'
    spy.socket = {}
    for func in [\pipe, \unpipe, \connect, \end, \on]
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

  should 'create a new ParserStream and SerializerStream', ->
    connection = new Connection
    ctorSpy.SS.should.have.been.called
    ctorSpy.PS.should.have.been.called
    connection.serializer.should.equal spy.ss
    connection.parser.should.equal spy.ps
    expect connection.socket .to.be.undefined

  describe '#connect', ->
    should 'create Socket connection', ->
      connection = connectWithDefaults!
      connection.socket.should.equal spy.socket

    should 'open the Socket using the given port and host', ->
      connectWithDefaults!
      createConnection = ctorSpy.Socket
      createConnection.should.have.been.calledOnce
      createConnection.should.have.been.calledWith 6667, \irc.example.com

    should 'pipe the Socket into the ParserStream', ->
      pipe = spy.socket.pipe = sinon.spy!
      connectWithDefaults!
      pipe.should.have.been.calledWith spy.ps

    should 'pipe the SerializerStream into the Socket', ->
      pipe = spy.ss.pipe = sinon.spy!
      connectWithDefaults!
      pipe.should.have.been.calledWith spy.socket

    should 'throw error if trying to connect twice', ->
      connection = connectWithDefaults!
      (-> connection.connect 6667).should.throw 'Already connected'

  should 'emit "message" event on incoming messages from the ParserStream', (done) ->
    connection = connectWithDefaults!
    connection.on \message, (message) ->
      message.command.should.equal 'QUIT'
      done!
    spy.ps.read = returnOnce { command: 'QUIT', type: 'command' }
    triggerReadable!

  describe '#close', ->
    should 'end and unpipe socket', ->
      connection = connectWithDefaults!
      connection.close!
      spy.ss.unpipe.should.have.been.calledWith spy.socket
      spy.socket.unpipe.should.have.been.calledWith spy.ps
      spy.socket.end.should.have.been.called

    should 'create fresh parser and serializer', ->
      connection = connectWithDefaults!
      connection.close!
      ctorSpy.SS.should.have.been.calledTwice
      ctorSpy.PS.should.have.been.calledTwice
      expect connection.socket .to.be.undefined

  describe '#send', ->
    should 'send command through Serializer', ->
      connection = connectWithDefaults!
      expected = {command: \PRIVMSG}
      serializerExpect expected, ->
        connection.send \PRIVMSG

    should 'accept variable number of arguments as parameters', ->
      connection = connectWithDefaults!
      expected = {command: \PET, parameters: [\the \Alot \of \parameters]}
      serializerExpect expected, ->
        connection.send \PET, \the, \Alot, \of, \parameters
      expected = {command: \NUMS, parameters: [\are, \fine, \42, \9001]}
      serializerExpect expected, ->
        connection.send \NUMS, \are, \fine, 42, 9001

    should 'accept raw message object as parameter', ->
      # Don't know yet if this is a good idea.
      connection = connectWithDefaults!
      expected = {command: \PRIVMSG, parameters: [\#channel \COOKIES!]}
      serializerExpect expected, ->
        connection.send expected

    should 'throw error on invalid arguments', ->
      connection = connectWithDefaults!
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
