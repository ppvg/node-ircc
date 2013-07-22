require! stream
i = it
pathToModule = modulePath \ParserStream

describe \ParserStream, ->

  i 'be a Transform stream', ->
    @ParserStream.prototype.should.have.property '_transform'

  i 'split the input into lines and emit objects', (done) ->
    count = 0
    @ps.on 'data', (data) ->
      data.should.be.an \object
      count += 1
      if count is 3 then done!
      if count > 3 then throw new Error "Too many objects emitted"
    for til 3 then @ps.write 'VERSION\r\n'

  i 'parse incoming lines', (done) ->
    @ps.write 'VERSION\r\n'
    @ps.write 'VERSION\r\n'
    @ps.on 'data', (data) ~>
      data.should.equal @mockMessage
    setImmediate ->
      parser.should.have.been.calledTwice
      done!

  beforeEach ->
    parser.reset!
    @mockMessage = { command: 'VERSION' }
    parser.returns @mockMessage
    @ps = new @ParserStream

  before ->
    mockery.enable();
    mockery.registerAllowables [\stream pathToModule]
    mockery.registerMock \ircp, parser
    @ParserStream = require pathToModule

  after ->
    mockery.deregisterAll();
    mockery.disable();

  parser = sinon.stub!
  parser.parse = parser