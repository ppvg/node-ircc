module.exports = serialize = (message) ->
  if not message? then throw new Error 'No message specified'
  serializedMessage = [
    formatPrefix message
    formatCommand message
  ].join ''

serialize.serialize = serialize

/* Serialize the prefix from either the server or the nick, user and host. */
function formatPrefix message
  if message.server?
    prefix = message.server
  else if message.nick?
    prefix = message.nick
    if message.user? then prefix += "!" + message.user
    if message.host? then prefix += "@" + message.host

  if prefix?
    ":#prefix "
  else
    ''

/* Serialize the rest of the message from the command and the parameters */
function formatCommand message
  parameters = [message.command] ++ (message.parameters or [])
  parameters .= map (e) ->
    hasSpace = (e.toString!.indexOf ' ') isnt -1
    if hasSpace then ":#e" else e
  parameters.join ' '
