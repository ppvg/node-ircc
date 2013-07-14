should = it
pathToSerializerStream = path.join libPath, \protocol, \SerializerStream

serializer = sinon.stub!
serializer.serialize = serializer
mockResult = null
SerializerStream = null

before ->
  mockery.enable();
  mockery.registerAllowables [\stream pathToSerializerStream]
  mockery.registerMock \./serializer, serializer
  SerializerStream := require pathToSerializerStream
after ->
  mockery.deregisterAll();
  mockery.disable();

describe \SerializerStream, ->
  beforeEach ->
    serializer.reset!
    mockResult := 'VERSION'
    serializer.returns mockResult

  test = (done, expected, input) ->
    serializer.on \readable, ->
      expect serializer.read! .to.eql expected
      done!
    serializer.write input

  should 'be a Transform stream', ->
    SerializerStream.prototype.should.have.property '_transform'

  should 'serialize incoming message objects', (done) ->
    ss = new SerializerStream
    ss.on 'data', (data) ->
      data.should.be.a \string
      done!
    ss.write { command: 'VERSION' }

  should 'append \\r\\n to `serializer`ed string before emitting', (done) ->
    ss = new SerializerStream
    count = 0
    ss.on 'data', (data) ->
      data.should.equal mockResult+'\r\n'
      count += 1
      if count is 3 then done!
      if count > 3 then throw new Error "Too many lines emitted"
    for til 3 then ss.write { command: 'VERSION' }




