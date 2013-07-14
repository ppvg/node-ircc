require! stream
require! \./serializer

module.exports = class SerializerStream extends stream.Transform
  (options = {}) ~>
    options.objectMode = true
    super options

  _transform: (input, encoding, done) ->
    # TODO try / catch over serialize()
    @push (serializer.serialize input) + '\r\n'
    done!
