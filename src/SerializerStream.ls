require! stream
require! ircp

module.exports = class SerializerStream extends stream.Transform
  (options = {}) ~>
    options.objectMode = true
    super options

  _transform: (input, encoding, done) ->
    # TODO try / catch over serialize()
    @push (ircp.serialize input) + '\r\n'
    done!
