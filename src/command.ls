require! path
require! \./ConnectionServer

usage = """
    Usage:

    ircc port host
    ircc path/to/config.json
  """
args = process.argv.splice 2

if args.length is 1 and /\.json$/.test args[0]
  options = require path.resolve args[0]
else if args.length is 2
  port = Number args[0]
  if not port? or isNaN port
    throw new Error 'Invalid port (not a number)'
  options = {
    port: port
    host: args[1]
  }
else
  console.log usage
  process.exit!

server = new ConnectionServer options.port, options.host, options.socketPath || \./connection.sock
server.start!

