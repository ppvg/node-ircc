should = it
pathToModule = modulePath \protocol, \SerializerStream

describe \SerializerStream, ->

  should 'be a Transform stream', ->
    @SerializerStream.prototype.should.have.property '_transform'

  should 'serialize incoming message objects', (done) ->
    ss = new @SerializerStream
    ss.on 'data', (data) ->
      data.should.be.a \string
      done!
    ss.write { command: 'VERSION' }

  should 'append \\r\\n to `serializer`ed string before emitting', (done) ->
    ss = new @SerializerStream
    count = 0
    ss.on 'data', (data) ~>
      data.should.equal @mockResult+'\r\n'
      count += 1
      if count is 3 then done!
      if count > 3 then throw new Error "Too many lines emitted"
    for til 3 then ss.write { command: 'VERSION' }

  beforeEach ->
    serializer.reset!
    @mockResult = 'VERSION'
    serializer.returns @mockResult

  before ->
    mockery.enable();
    mockery.registerAllowables [\stream pathToModule]
    mockery.registerMock \./serializer, serializer
    @SerializerStream = require pathToModule

  after ->
    mockery.deregisterAll();
    mockery.disable();

  serializer = sinon.stub!
  serializer.serialize = serializer

  test = (done, expected, input) ->
    serializer.on \readable, ->
      expect serializer.read! .to.eql expected
      done!
    serializer.write input
