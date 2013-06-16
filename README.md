Aether is a modular IRC client library for Node.js. It consists of the following modules:

- `parser` and `serializer`, which convert IRC message strings into objects and vice-versa.
- `ParserStream` and `SerializerStream`, which simplifies connecting the `parser` and `serializer` to a `Socket`.
- `Connection`, which makes it easy to set up and break down an connection to an IRC server.
- _(coming soon)_ `Client`, which manages a connection and abstracts away the nitty-gritty details of IRC message formatting.

This modular approach allows you to use or extend aether at whichever level of abstraction you need. It also makes unit testing a breeze (test coverage is currently 100%).

Keep in mind that aether is a work in progress. There are other, more complete IRC libraries for Node. See e.g. [node-irc][1] and [IRC-js][2].

  [1]: https://github.com/martynsmith/node-irc
  [2]: https://github.com/gf3/IRC-js

Aether has no dependencies other than Node.js 0.10.x (or 0.9.8+).
