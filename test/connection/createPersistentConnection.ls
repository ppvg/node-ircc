should = it
pathToModule = modulePath \connection, \createPersistentConnection

describe 'createPersistentConnection', ->

  should 'spawn itself to start PersistentConnectionServer', ->
    pc = @createPersistentConnection!
    spy.spawn.should.have.been.calledOnce
    args = spy.spawn.args[0][1]
    expect args .to.be.an.array
    args[0].should.equal pathToModule+'.js'

  should 'resolve socket fliename to absolute path', ->
    pc = @createPersistentConnection \filename.sock
    spy.resolve.should.have.been.calledOnce
    spy.resolve.should.have.been.calledWith \filename.sock

  should 'default to ircc.sock if no filename given', ->
    pc = @createPersistentConnection!
    spy.resolve.should.have.been.calledOnce
    spy.resolve.should.have.been.calledWith \ircc.sock

  should 'pass resolved filename as argument when spawning server', ->
    pc = @createPersistentConnection \ircc.sock
    args = spy.spawn.args[0][1]
    args[1].should.equal \/path/to/ircc.sock

  should "create client if server process outputs 'listening'", ->
    spy.server.stdout.on.yields \listening
    pc = @createPersistentConnection!
    spy.PCClient.should.have.been.calledWithNew

  should "create client if server process outputs 'superfluous'", ->
    spy.server.stdout.on.yields \superfluous
    pc = @createPersistentConnection!
    spy.PCClient.should.have.been.calledWithNew

  describe 'when creating the client', ->
    should 'create socket connection to server', ->
      spy.server.stdout.on.yields \listening
      pc = @createPersistentConnection!
      spy.createConnection.should.have.been.calledOnce
      spy.createConnection.should.have.been.calledWith \/path/to/ircc.sock
      spy.PCClient.should.have.been.calledWith spy.socket

  should "expose client via 'client' event", (done) ->
    serverOutput = catchCallback spy.server.stdout, \on, \data
    pc = @createPersistentConnection!
    pc.on \client, (client) ->
      expect client .to.equal spy.client
      done!
    serverOutput \listening

  should "emit 'error' if server process outputs to stderr", (done) ->
    errorOutput = catchCallback spy.server.stderr, \on, \data
    pc = @createPersistentConnection!
    pc.on \error, (error) ->
      error.message.should.equal \borkborkbork
      done!
    errorOutput \borkborkbork

  should "emit 'error' if server process outputs unexpected data", (done) ->
    serverOutput = catchCallback spy.server.stdout, \on, \data
    pc = @createPersistentConnection!
    pc.on \error, (error) ->
      error.message.should.equal "Unexpected server output: borkborkbork"
      done!
    serverOutput \borkborkbork

  should.skip 'functional tests to test how PersistentConnectionServer is started?'

  beforeEach ->
    for k, s of spy when s.resetBehavior?
      s.reset!
      s.resetBehavior!
    spy.client = { on: sinon.stub! }
    spy.socket = {}
    spy.PCClient.returns spy.client
    spy.createConnection.returns spy.socket
    spy.resolve.returns \/path/to/ircc.sock
    spy.spawn.returns spy.server
    spy.server.stdout.on = sinon.stub!
    spy.server.stderr.on = sinon.stub!

  before ->
    mockery.enable!
    mockery.registerMock \dnode, spy.dnode
    mockery.registerMock \net, { createConnection: spy.createConnection }
    mockery.registerMock \path, { resolve: spy.resolve }
    mockery.registerMock \./PersistentConnectionServer, -> throw new Error 'Server should be spawned directly'
    mockery.registerMock \./PersistentConnectionClient, spy.PCClient
    mockery.registerMock \child_process, { spawn: spy.spawn }
    mockery.registerAllowables [pathToModule, \events], true
    @createPersistentConnection = require pathToModule

  after ->
    mockery.deregisterAll!
    mockery.disable!

  spy =
    PCClient: sinon.stub!
    createConnection: sinon.stub!
    resolve: sinon.stub!
    spawn: sinon.stub!
    server:
      stdout: {}
      stderr: {}

