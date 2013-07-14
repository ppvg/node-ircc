module.exports.merge = (options, defaults) ->
  result = ^^defaults
  for key of defaults
    result[key]? = options[key]
  result
