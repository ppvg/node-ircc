should = it

serialize = serializer = require path.join libPath, \protocol, \serializer

describe \serializer, ->

  test = (expected, input) ->
    expect (serialize input) .to.eql expected

  should 'be callable as require("serializer")() and require("serialize").serialize()`', ->
    serializer.should.equal serializer.serialize
    message = {command:\VERSION}
    serializer(message).should.eql 'VERSION'
    serializer.serialize(message).should.eql 'VERSION'

  should 'serialize "VERSION"', ->
    test 'VERSION', command: \VERSION

  should 'serialize "VERSION a.b.c"', ->
    test 'VERSION a.b.c', {
      command: \VERSION
      parameters: [\a.b.c]
    }

  should 'serialize "VERSION a.b.c d.e.f"', ->
    test 'VERSION a.b.c d.e.f', {
      command: \VERSION
      parameters: [\a.b.c, 'd.e.f']
    }

  should 'serialize "VERSION :trailing text is also a parameter"', ->
    test 'VERSION :trailing text is also a parameter', {
      command: \VERSION
      parameters: ['trailing text is also a parameter']
    }

  should 'serialize "VERSION #hello :trailing text', ->
    test 'VERSION #hello :trailing text', {
      command: \VERSION
      parameters: ['#hello', 'trailing text']
    }

  should 'serialize ":irc.example.com VERSION"', ->
    test ':irc.example.com VERSION', {
      command: \VERSION
      server: \irc.example.com
    }

  should 'serialize ":nick VERSION"', ->
    test ':nick VERSION', {
      command: \VERSION
      nick: \nick
    }

  should 'serialize ":nick!user VERSION"', ->
    test ':nick!user VERSION', {
      command: \VERSION
      nick: \nick
      user: \user
    }

  should 'serialize ":nick@host VERSION"', ->
    test ':nick@host VERSION', {
      command: \VERSION
      nick: \nick
      host: \host
    }

  should 'serialize ":nick!user@host VERSION"', ->
    test ':nick!user@host VERSION', {
      command: \VERSION
      nick: \nick
      user: \user
      host: \host
    }

  should 'throw Error if message object invalid or missing', ->
    (-> serialize!)
      .should.throw 'No message to serialize'
    (-> serialize {cookies:'are awesome'})
      .should.throw /^Invalid message/
    (-> serialize {command:'BOO',server:'localhost',user:'greedy'})
      .should.throw /^Invalid message/

