ircc
====

[![Build Status](https://drone.io/github.com/PPvG/node-ircc/status.png)](https://drone.io/github.com/PPvG/node-ircc/latest) [![Code Coverage](https://drone.io/github.com/PPvG/node-ircc/files/coverage.png)](https://drone.io/github.com/PPvG/node-ircc/latest)

Modular IRC connection library for Node.js, based on two principles:


### 1. doesn't interfere with the messages

Doesn't respond to `PING`s. Doesn't send `NICK` and `USER` at the start of a session. Doesn't do any parsing beyond identifying the parts of a message.


### 2. many levels of abstraction

Can be used or extended at whichever level of abstraction you need. There are four:

1. `parser` and `serializer`<br />
    Convert IRC message strings into objects and vice-versa.
2. `ParserStream` and `SerializerStream`<br />
    Simplify connecting the `parser` and `serializer` to a `Socket` connection.
3. `Connection`<br />
    Set up, manage and break down an connection to an IRC server.
4. `PersistentConnection`<br />
    Allows you to decouple the Connection from your bot code, making it possible to reload your bot without breaking the connection to the IRC server.


### Installation

```
npm install ircc
```

### Dependencies

- [dnode](https://github.com/substack/dnode) (optional, used by the `PersistentConnection`)
- Node.js 0.9.8 or above.


### Example

```
  var ircc = require('ircc');

  var connection = ircc('ircc.sock');

  connection.on('open', function(conn) {
    conn.on('message', function(message) {
      console.log(message);
    });
    connection.connect(6667, 'irc.example.com');
    connection.send('HELP');
  });
```


API
---

### `ircc.parser`

#### `parser.parse(line)`
#### `parser(line)`

Takes an IRC message as raw text and returns a message object. A few examples (via the `node` REPL):

```
> ircc.parser.parse(':nick!user@host PART #channel');
{ command: 'PART',
  parameters: [ '#channel' ],
  nick: 'nick',
  user: 'user',
  host: 'host',
  type: 'command' }
```


```
> ircc.parser.parse(':irc.example.com 001 botname :Welcome to the example IRC network!');
{ command: 'WELCOME',
  parameters:
   [ 'botname',
     'Welcome to the example IRC network!' ],
  server: 'irc.example.com',
  code: '001',
  type: 'reply' }
```

Throws an `Error` if the message can't be parsed.


### `ircc.serializer`

#### `serializer.serialize(message)`
#### `serializer(message)`

The reverse of `parser`. Takes a message object and turns it into a string.

```
> ircc.serializer(ircc.parser(':nick!user@host PART #channel'));
':nick!user@host PART #channel> '
```

Throws an `Error` if the object is not a valid message.


### `codes`

#### `codes.convert()`

Find the name and type of an IRC command. Known numeric commands are converted to their human-readable form. A few examples:

```
> ircc.codes.convert('001');
{ name: 'WELCOME', type: 'reply' }
```


```
> ircc.codes.convert('401');
{ name: 'NOSUCHNICK', type: 'error' }
```


```
> ircc.codes.convert('NOTICE');
{ name: 'NOTICE', type: 'command' }
```

Possible values for `type` are 'reply', 'error', 'command' and 'unknown'.


### `ircc.ParserStream` and `ircc.SerializerStream`

```
var serializer = new ircc.SerializerStream();
var parser = new ircc.ParserStream();
```

These are both [Transform streams][4]. The most common use case is to `.pipe()` them to a `Socket` connection to an IRC server:

  [4]: http://nodejs.org/api/stream.html#stream_class_stream_transform

```
var socket = net.createConnection(/*...*/);
serializer.pipe(socket).pipe(parser);

The `parser` emits parsed IRC message objects:

parser.on('readable', function() {
  var message;
  while (var message = parser.read()) {
    console.log(message); // { command: 'WELCOME', parameters: [...etc.
  }
});
```

... and you can `.write()` outgoing message objects to the `serializer`:

```
var message = {
  command: 'PRIVMSG',
  parameters: [
    '#channel',
    'Hi there, folks!'
  ]
};
serializer.write(message);
```


### `ircc.Connection`

```
var connection = new ircc.Connection();
```

Sets up a connection to an IRC server and then gets out of the way.

`Connection` makes it easy to send and receive IRC messages but doesn't do any interpretation on them. E.g. it doesn't automatically respond to `PING` messages or send `NICK` and `USER` commands at the start of the session.

#### connection.connect(...)

Connect to an IRC server. Takes the same arguments as [`socket.connect(...)`][5]. Throws an error if the `connection` is already up.

  [5]: http://nodejs.org/api/net.html#net_socket_connect_port_host_connectlistener

#### connection.close()

Close the connection. Throws an error if it was already closed.

#### connection.send(messageObject)
#### connection.send(command, [parameters...])

Send a message to the IRC server. The first argument is mandatory and can either be a message object or a string.

If the first argument is an object, no further arguments are expected. If it's a string, it's treated as the command and any further arguments are interpreted as the message parameters.

For example:

```
connection.send({command: 'KICK', parameters: ['#channel', 'marvin']});
connection.send('PRIVMSG', '#channel', 'Hi there, folks!');
```

#### connection.on('message', function(message) {})

Emitted when a message is received from the server. The `message` is an object, as returned by `parser.parse()`.

#### connection.on('close', function() {})

Emitted after the connection is closed.
