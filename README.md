# ircc

[![Build Status](https://drone.io/github.com/PPvG/node-ircc/status.png)](https://drone.io/github.com/PPvG/node-ircc/latest) [![Code Coverage](https://drone.io/github.com/PPvG/node-ircc/files/coverage.png)](https://drone.io/github.com/PPvG/node-ircc/files/coverage.html)

IRC connection library for Node.js.

Sets up a connection to an IRC server and then gets out of the way. It doesn't respond to `PING`s, doesn't send `NICK` and `USER` at the start of the session, et cetera.

#### Installation

`$ npm install ircc`

#### Dependencies

Node.js 0.9.8 or above.

## Example

    var ircc = require('ircc');

    var connection = new ircc.Connection();
    connection.connect(6667, 'irc.example.com');

    connection.on('message', function(message) {
      if (message.command === 'PRIVMSG')
        console.log message.parameters[0]+":", message.parameters[1]
        connection.send('PRIVMSGM', message.parameters[0], "HELLO!");
    });

    connection.on('connect', function() {
      connection.send('NICK', 'PrawnBoy');
      connection.send('USER', 'prawnboy', 0, 0, 'Insanity Prawn Boy');
    });


## API

### ircc.Connection

    var connection = new ircc.Connection();

#### connection.connect(...)

Connect to an IRC server. Takes the same arguments as [`socket.connect(...)`][1]. Throws an error if the connection is already up.

  [1]: http://nodejs.org/api/net.html#net_socket_connect_port_host_connectlistener

#### connection.close()

Close the connection. Throws an error if it was already closed.

#### connection.send(messageObject)
#### connection.send(command, [parameters...])

Send a message to the IRC server. The first argument is mandatory and can either be a message object or a string.

If the first argument is an object, no further arguments are expected. If it's a string, it's treated as the command and any further arguments are interpreted as the message parameters.

For example:

    connection.send({command: 'KICK', parameters: ['#channel', 'marvin']});
    connection.send('PRIVMSG', '#channel', 'Hi there, folks!');

#### connection.on('message', function(message) {})

Emitted when a message is received from the server. The `message` is an object, such as:

    { command: 'PART',
      parameters: [ '#channel' ],
      nick: 'nick',
      user: 'user',
      host: 'host',
      type: 'command' }

...or:

    { command: 'WELCOME',
      parameters:
       [ 'botname',
         'Welcome to the example IRC network!' ],
      server: 'irc.example.com',
      code: '001',
      type: 'reply' }

The `type` is either 'command', 'reply', 'error' or 'unknown'. If the message was a numeric response, `code` will be the original command, and `command` will be a human-readable substitute. For more details, see [ircp][ircp].

  [ircp]: https://npmjs.org/package/ircp

#### connection.on('connect', function() {})

Emitted once the connection is succesfully set up.

#### connection.on('close', function() {})

Emitted after the connection is closed.


### ircc.ParserStream and ircc.SerializerStream

    var serializer = new ircc.SerializerStream();
    var parser = new ircc.ParserStream();

These are used internally by `Connection`. They're [Transform streams][2] that form a stream-based interface to [ircp][ircp]'s `parse` and `serialize` functions. The most common use case is to `.pipe()` them to a `Socket` connection to an IRC server:

  [2]: http://nodejs.org/api/stream.html#stream_class_stream_transform

    var socket = net.createConnection(/*...*/);
    serializer.pipe(socket).pipe(parser);

    // The parser emits ircp message objects:
    parser.on('readable', function() {
      var message;
      while (var message = parser.read()) {
        console.log(message); // { command: 'WELCOME', parameters: [...etc.
      }
    });

    // You can .write() outgoing message objects to the serializer:
    var message = {
      command: 'PRIVMSG',
      parameters: [
        '#channel',
        'Hi there, folks!'
      ]
    };
    serializer.write(message);

Note that the SerializerStream doesn't take strings, just message objects.


## License

BSD 2-clause. See [LICENSE](https://github.com/PPvG/node-ircp/blob/master/LICENSE).