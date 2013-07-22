i = it
pathToModule = modulePath \Connection

describe 'Connection', ->

  i 'idle until #connect is called', (done) ->
    setImmediate ~>
      expect @connection.socket .to.not.exist
      done!

  i 'create a new ParserStream and SerializerStream', ->
    ctorSpy.SS.should.have.been.called
    ctorSpy.PS.should.have.been.called
    @connection.serializer.should.equal spy.ss
    @connection.parser.should.equal spy.ps
    expect @connection.socket .to.be.undefined

  describe '#connect', ->

    # TODO
    i.skip 'handle TLS connection'

    i 'create Socket connection', ->
      @connect!
      @connection.socket.should.equal spy.socket

    i 'open the Socket using the given port and host', ->
      @connect!
      createConnection = ctorSpy.Socket
      createConnection.should.have.been.calledOnce
      createConnection.should.have.been.calledWith 6667, \irc.example.com

    i 'pipe the Socket into the ParserStream', ->
      @connect!
      spy.socket.pipe.should.have.been.calledWith spy.ps
      # Should not close parser on 'close':
      spy.socket.pipe.args[0][1].should.eql { end: false }

    i 'pipe the SerializerStream into the Socket', ->
      @connect!
      spy.ss.pipe.should.have.been.calledWith spy.socket

    i 'throw error if trying to connect twice', ->
      @connect!
      @connect.should.throw 'Already connected'

    i "emit 'connect' event after connection is established", (done) ->
      triggerConnect = catchCallback spy.socket, \on, \connect
      @connect!
      @connection.on \connect, done
      triggerConnect!

    i "emit 'error' event if connection can't be made", (done) ->
      triggerError = catchCallback spy.socket, \on, \error
      @connect!
      @connection.on \error, done
      triggerError!

  i 'emit "message" event on incoming messages from the ParserStream', (done) ->
    @connect!
    @connection.on \message, (message) ->
      message.command.should.equal 'QUIT'
      done!
    spy.ps.read = returnOnce { command: 'QUIT', type: 'command' }
    @triggerReadable!

  describe '#close', ->
    i 'end and unpipe socket', ->
      @connect!
      @connection.close!
      spy.ss.unpipe.should.have.been.calledWith spy.socket
      spy.socket.unpipe.should.have.been.calledWith spy.ps
      spy.socket.end.should.have.been.called

  describe '#send', ->
    i 'send command through Serializer', ->
      @connect!
      serializerExpect {command: \PRIVMSG}, ~>
        @connection.send \PRIVMSG

    i 'accept variable number of arguments as parameters', ->
      @connect!
      expected = {command: \PET, parameters: [\the \Alot \of \parameters]}
      serializerExpect expected, ~>
        @connection.send \PET, \the, \Alot, \of, \parameters
      expected = {command: \NUMS, parameters: [\are, \fine, \42, \9001]}
      serializerExpect expected, ~>
        @connection.send \NUMS, \are, \fine, 42, 9001

    i 'accept raw message object as parameter', ->
      # Don't know yet if this is a good idea.
      @connect!
      expected = {command: \PRIVMSG, parameters: [\#channel \COOKIES!]}
      serializerExpect expected, ~>
        @connection.send expected

    i 'throw error on invalid arguments', ->
      @connect!
      (~> @connection.send [\TWO \COMMANDS])
        .should.throw 'Invalid command'
      (~> @connection.send {commmmmadn: \MISSPELL})
        .should.throw 'Invalid command'

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
    @connection = new @Connection

  before ->
    mockery.enable!
    mockery.registerAllowables [\events pathToModule], true
    mockery.registerMock \./SerializerStream, createMock \SS
    mockery.registerMock \./ParserStream, createMock \PS
    mockery.registerMock \net, { createConnection: createMock \Socket }
    @Connection = require pathToModule
    @connect = ~>
      @connection.connect 6667, \irc.example.com

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
