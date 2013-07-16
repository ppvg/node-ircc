should = it
pathToModule = modulePath \connection, \Connection

describe 'Connection', ->

  should 'idle until #connect is called', (done) ->
    connection = new @Connection
    setImmediate ->
      expect connection.socket .to.not.exist
      done!

  should 'create a new ParserStream and SerializerStream', ->
    connection = new @Connection
    ctorSpy.SS.should.have.been.called
    ctorSpy.PS.should.have.been.called
    connection.serializer.should.equal spy.ss
    connection.parser.should.equal spy.ps
    expect connection.socket .to.be.undefined

  describe '#connect', ->

    # TODO accept instance of net.Socket as input

    # TODO emit 'connect' event

    should 'create Socket connection', ->
      connection = @defaultConnection!
      connection.socket.should.equal spy.socket

    should 'open the Socket using the given port and host', ->
      @defaultConnection!
      createConnection = ctorSpy.Socket
      createConnection.should.have.been.calledOnce
      createConnection.should.have.been.calledWith 6667, \irc.example.com

    should 'pipe the Socket into the ParserStream', ->
      pipe = spy.socket.pipe = sinon.spy!
      @defaultConnection!
      pipe.should.have.been.calledWith spy.ps

    should 'pipe the SerializerStream into the Socket', ->
      pipe = spy.ss.pipe = sinon.spy!
      @defaultConnection!
      pipe.should.have.been.calledWith spy.socket

    should 'throw error if trying to connect twice', ->
      connection = @defaultConnection!
      (-> connection.connect 6667).should.throw 'Already connected'

  should 'emit "message" event on incoming messages from the ParserStream', (done) ->
    connection = @defaultConnection!
    connection.on \message, (message) ->
      message.command.should.equal 'QUIT'
      done!
    spy.ps.read = returnOnce { command: 'QUIT', type: 'command' }
    @triggerReadable!

  describe '#close', ->
    should 'end and unpipe socket', ->
      connection = @defaultConnection!
      connection.close!
      spy.ss.unpipe.should.have.been.calledWith spy.socket
      spy.socket.unpipe.should.have.been.calledWith spy.ps
      spy.socket.end.should.have.been.called

    should 'create fresh parser and serializer', ->
      connection = @defaultConnection!
      connection.close!
      ctorSpy.SS.should.have.been.calledTwice
      ctorSpy.PS.should.have.been.calledTwice
      expect connection.socket .to.be.undefined

  describe '#send', ->
    should 'send command through Serializer', ->
      connection = @defaultConnection!
      expected = {command: \PRIVMSG}
      serializerExpect expected, ->
        connection.send \PRIVMSG

    should 'accept variable number of arguments as parameters', ->
      connection = @defaultConnection!
      expected = {command: \PET, parameters: [\the \Alot \of \parameters]}
      serializerExpect expected, ->
        connection.send \PET, \the, \Alot, \of, \parameters
      expected = {command: \NUMS, parameters: [\are, \fine, \42, \9001]}
      serializerExpect expected, ->
        connection.send \NUMS, \are, \fine, 42, 9001

    should 'accept raw message object as parameter', ->
      # Don't know yet if this is a good idea.
      connection = @defaultConnection!
      expected = {command: \PRIVMSG, parameters: [\#channel \COOKIES!]}
      serializerExpect expected, ->
        connection.send expected

    should 'throw error on invalid arguments', ->
      connection = @defaultConnection!
      (-> connection.send [\TWO \COMMANDS])
        .should.throw 'Invalid command'
      (-> connection.send {commmmmadn: \MISSPELL})
        .should.throw 'Invalid command'


  should.skip 'handle TLS connection', ->
  should.skip 'connect to password-protected servers', ->
  should.skip 'emit "connected" event?', ->

  beforeEach ->
    [s.reset! for k, s of ctorSpy]
    @triggerReadable = ->
      throw new Error '@parser.on not called yet!'
    spy.socket = {}
    for func in [\pipe, \unpipe, \connect, \end, \on]
      spy.socket[func] = sinon.spy!
    spy.ss = {}
    for func in [\pipe, \unpipe, \write]
      spy.ss[func] = sinon.spy!
    spy.ps :=
      on: (event, cb) ~>
        if event is \readable
          @triggerReadable = cb

  before ->
    mockery.enable!
    mockery.registerAllowables [\events pathToModule], true
    mockery.registerMock \../protocol/SerializerStream, createMock \SS
    mockery.registerMock \../protocol/ParserStream, createMock \PS
    mockery.registerMock \net, { createConnection: createMock \Socket }
    @Connection = require pathToModule
    @defaultConnection = ->
      (connection = new @Connection).connect 6667, \irc.example.com
      connection

  after ->
    mockery.deregisterAll!
    mockery.disable!

  ctorSpy =
    SS: sinon.spy!
    PS: sinon.spy!
    Socket: sinon.spy!
  spy = {}

  /* Creates a mock constructor, which calls the ctorSpy and returns the instance spy. */
  createMock = (name) ~>
    (...args) ->
      ctorSpy[name] ...args
      spy[name.toLowerCase!]

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

  returnOnce = (value) ->
    called = false
    ->
      if not called
        called := true
        value
      else
        null


