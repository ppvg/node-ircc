require! net
require! fs

# TODO: refactor back into ConnectionServer

module.exports = createUnixServer = (path, connectionListener) ->
  server = net.createServer connectionListener
  server.on \error, (error) ->
    if error.code is \EADDRINUSE
      sock = net.createConnection path, ->
        server.emit \aborted
      sock.on \error, (error) ->
        if error.code is \ECONNREFUSED
          fs.unlink path
          server.start!
  server.start = -> server.listen path
  server
