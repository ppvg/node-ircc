should = it

parse = parser = require modulePath \protocol, \parser

describe \parser, ->

  should 'parse simple commands', ->
    message = parse 'VERSION'
    message.command.should.equal \VERSION
    message.parameters.should.eql []
    message.should.not.contain.keys [\server \nick \user \host]

  should 'convert known numerical command to human-readable ones', ->
    message = parse '001'
    message.command.should.equal \WELCOME
    message.code.should.equal '001'

  should 'determine the type of command', ->
    message = parse '001'
    message.command.should.equal \WELCOME
    message.type.should.equal \reply
    message = parse 'INFO'
    message.command.should.equal \INFO
    message.type.should.equal \command
    message = parse '401'
    message.command.should.equal \NOSUCHNICK
    message.type.should.equal \error
    message = parse 'UNKNOWNFANTASYCODE'
    message.command.should.equal \UNKNOWNFANTASYCODE
    message.type.should.equal \unknown

  should 'parse simple parameters', ->
    message = parse 'NICK TestBot'
    message.parameters.should.eql [\TestBot]
    message = parse 'MODE AbUser -o'
    message.parameters.should.eql [\AbUser \-o]

  should 'parse trailing text as a parameter', ->
    message = parse 'PRIVMSG user :Ohai thar!'
    message.parameters.should.eql [\user, 'Ohai thar!']

  should 'parse :server prefix', ->
    message = parse ':irc.example.com NOTICE'
    message.command.should.equal \NOTICE
    message.server.should.equal \irc.example.com
    message.should.not.include.keys \nick \user \host

  should 'parse :nick prefix', ->
    message = parse ':nick PART #channel'
    message.command.should.equal \PART
    message.nick.should.equal \nick
    message.should.not.include.keys \user \server
    message.parameters.should.eql [\#channel]

  should 'parse :nick!user prefix', ->
    message = parse ':nick!user PART #channel'
    message.command.should.equal \PART
    message.nick.should.equal \nick
    message.user.should.equal \user
    message.should.not.include.keys \host \server
    message.parameters.should.eql [\#channel]

  should 'parse :nick@host prefix', ->
    message = parse ':nick@host PART #channel'
    message.command.should.equal \PART
    message.nick.should.equal \nick
    message.host.should.equal \host
    message.should.not.include.keys \user \server
    message.parameters.should.eql [\#channel]

  should 'parse :nick!user@host prefix', ->
    message = parse ':nick!user@host PART #channel'
    message.command.should.equal \PART
    message.nick.should.equal \nick
    message.user.should.equal \user
    message.host.should.equal \host
    message.should.not.include.key \server
    message.parameters.should.eql [\#channel]

  should 'strip \\r\\n from the end of the input, if applicable', ->
    message = parse 'VERSION\r\n'
    message.command.should.equal \VERSION
    message.parameters.should.be.empty

  should 'be reasonably performant (<0.1ms per iteration)', ->
    /* 0.1ms should be more than enough on most hardware, even under load */
    iterations = 5000
    start = new Date!getTime!
    while iterations > 0
      message = parse ':nick!user@host VERSION a.b.c :long argument'
      iterations -= 1

    duration = new Date!getTime! - start
    duration.should.be.lessThan 500
    message.command.should.equal \VERSION
    message.parameters.should.eql [\a.b.c 'long argument']
    message.nick.should.equal \nick
    message.user.should.equal \user
    message.host.should.equal \host

  should 'throw Error if incoming message is complete gibberish', ->
    (-> parse ':/)').should.throw 'Not a valid IRC message (not even a slightly).'
    (-> parse ':irc.example.com').should.throw 'Not a valid IRC message (not even a slightly).'

  should.skip 'throw more Errors'