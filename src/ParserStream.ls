require! stream
require! ircp

module.exports = class ParserStream extends stream.Transform
  (options = {}) ~>
    options.objectMode = true
    super options
    @buffer = ''

  _transform: (input, encoding, done) ->
    lines = @_split input.toString!
    for line in lines
      @push ircp.parse line
    done!

  _split: (input) ->
    lines = (@buffer += input).split /\r\n/
    @buffer = lines.pop!
    lines
