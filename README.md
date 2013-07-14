[![Build Status](https://drone.io/github.com/PPvG/node-ircc/status.png)](https://drone.io/github.com/PPvG/node-ircc/latest) [![Code Coverage](https://drone.io/github.com/PPvG/node-ircc/files/coverage.png)](https://drone.io/github.com/PPvG/node-ircc/latest)

Ircc is a modular IRC client library for Node.js. It consists of the following modules:

- `parser` and `serializer`, which convert IRC message strings into objects and vice-versa.
- `ParserStream` and `SerializerStream`, which simplifies connecting the `parser` and `serializer` to a `Socket`.
- `Connection`, which makes it easy to set up and break down an connection to an IRC server.
- `ConnectionServer` and `ConnectionClient`, which allow you to decouple the Connection from your bot code. Amongst other things, this makes it possible to reload your bot without breaking the connection to the IRC server.

This modular approach allows you to use or extend ircc at whichever level of abstraction you need. It also makes unit testing a breeze.

Keep in mind that ircc is a work in progress. There are other, more complete IRC libraries for Node. See e.g. [node-irc][1] and [IRC-js][2].

  [1]: https://github.com/martynsmith/node-irc
  [2]: https://github.com/gf3/IRC-js

Ircc has one optional dependency, [`dnode`][3], which is needed for the `ConnectionServer` and `ConnectionClient`. It has no other dependencies and runs on Node.js 0.9.8 and above.

  [3]: https://github.com/substack/dnode
