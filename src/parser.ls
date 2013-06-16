require! \./regex
require! \./codes

module.exports = parse = (line) ->
  line |> split |> parsePrefix |> parseCommand |> parseParameters

parse.parse = parse

function split line
  if m = line.match regex.split
    return message = prefix: m.1, command: m.2, parameters: m.3
  else
    throw new Error 'Not a valid IRC message (not even a slightly).'

function parsePrefix message
  if message.prefix?
    if m = message.prefix.match regex.prefix
      hostmask = nick: m.1, user: m.2, host: m.3
      for k, v of hostmask when not v? then delete hostmask[k]
      message <<< hostmask
    else
      message.server = message.prefix
  delete message.prefix
  message

function parseCommand message
  command = codes.convert message.command
  if command.name isnt message.command
    message.code = message.command
  message.command = command.name
  message.type = command.type
  message

function parseParameters message
  parameters = []
  if m = message.parameters.match regex.parameters
    if m.1? and m.1.length > 1
      parameters = m.1.split ' '
    if m.2?
      parameters.push m.2
  message.parameters = parameters
  message
