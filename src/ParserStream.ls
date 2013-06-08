require! stream
require! \./parser

module.exports = class ParserStream extends stream.Transform
  (options = {}) ->
    @buffer = ''
    options.objectMode = true
    super options

  _transform: (input, encoding, done) ->
    lines = @_split input.toString!
    for line in lines
      @push parser.parse line
    done!

  _split: (input) ->
    lines = (@buffer += input).split /\r\n/
    @buffer = lines.pop!
    lines

