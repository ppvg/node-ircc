require! \./Connection

module.exports = createConnection = (port, host, connectListener) ->
  connection = new Connection
  if typeof connectListener is \function
    connection.on \connect, connectListener
  connection.connect port, host
  connection
