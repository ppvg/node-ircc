module.exports = serialize = (message) ->
  if not message? then throw new Error 'No message to serialize'
  [ formatPrefix message
    formatCommand message
  ].join ''

serialize.serialize = serialize

/* Serialize the prefix from either the server or the nick, user and host. */
function formatPrefix message
  if message.server? and (message.nick? or message.user? or message.host?)
    throw new Error 'Invalid message object (has both server AND nick|user|host)'
  if message.server?
    prefix = message.server
  else if message.nick?
    prefix = message.nick
    if message.user? then prefix += "!" + message.user
    if message.host? then prefix += "@" + message.host
  else
    return ''
  return ":#prefix "

/* Serialize the rest of the message from the command and the parameters */
function formatCommand message
  if not message.command? then throw new Error 'Invalid message object (missing command)'
  parameters = [message.command] ++ (message.parameters or [])
  parameters .= map (e) ->
    hasSpace = (e.toString!.indexOf ' ') isnt -1
    if hasSpace then ":#e" else e
  parameters.join ' '
