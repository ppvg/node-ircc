{spawn} = require \child_process
require! [\gaze \fs \path \q]

/* Tasks */

task \build 'Compile all LiveScript from src/ to JavaScript in lib/' ->
  clean!
    .then build

task \test 'Run the tests' ->
  clean!
    .then build
    .done test

task \watch 'Watch, compile and test files.' ->
  gaze [\src/*], ->  @on \all, ->
    invoke \test
  gaze [\test/*, ], -> @on \all, ->
    clearTerminal!
    test!
  invoke \test

task \coverage 'Generate code coverage report and badge using jscoverage' ->
  process.env.\IRCC_COV = 1
  jscoverage!
    .then ->
      file = fs.openSync \coverage.html, \w
      mocha [\--reporter \html-cov], [\ignore, file, \ignore]
    .then ->
      console.log "Code coverage report written to 'coverage.html'"
    .catch (e) ->
      console.error 'Unable to generate code coverage report:', e
    .then ->
      file = fs.openSync \coverage.json, \w
      mocha [\--reporter \json-cov], [\ignore, file, \ignore]
    .then ->
      try
        badge = require \coverage-badge
      catch
        throw new Error "Unable to generate coverage badge: 'coverage-badge' is not installed"
      json = JSON.parse fs.readFileSync \coverage.json
      file = fs.createWriteStream \coverage.png
      badge json.coverage .pipe file
    .then ->
      console.log "Code coverage badge written to 'coverage.png'"
    .catch (e) ->
      console.error 'Unable to generate code coverage badge:', e
    .finally ->
      spawn \rm [\-r, \lib-cov]

/* Actions */

clean = ->
  deferred = q.defer!
  (spawn \rm [\-r \./lib]).on \exit, deferred~resolve
  deferred.promise

build = ->
  clean!
    .then ->
      dirs = [\.] ++ getDirs \src
      promises = [livescript (path.join \lib, d), (path.join \src, d) for d in dirs]
      q.all promises
    .catch (error) -> console.error "Couldn't compile LiveScript", error

test = ->
  clearTerminal!
  mocha [\--reporter, \spec, \-G], \inherit

livescript = (libPath, srcPath) ->
  deferred = q.defer!

  srcFiles = [path.join srcPath, file for file in dir srcPath when /\.ls$/.test file]
  lsc = spawn \lsc, [\-bco libPath] ++ srcFiles

  stderrOutput = ''
  lsc.stderr.on \data, -> stderrOutput += it.toString!
  lsc.on \exit, (error) ->
    if error then deferred.reject stderrOutput
    else deferred.resolve!

  deferred.promise

jscoverage = ->
  build!.then ->
    jscov = spawn \jscoverage, ['--no-highlight', 'lib', 'lib-cov'], {stdio: 'inherit'}
    deferred = q.defer!
    jscov.on \exit, (code, signal) ->
      if signal? or code isnt 0 then deferred.reject!
      else deferred.resolve!
    deferred.promise

mocha = (args, io=\ignore) ->
  path = \node_modules/mocha/bin/mocha
  defaults =
    \-c \--compilers \ls:LiveScript
    \-r \test/common
  args = defaults.concat args
  mocha = spawn path, args, { stdio: io }
  deferred = q.defer!
  mocha.on \exit, (code, signal) ->
    if signal? or code isnt 0 then deferred.reject!
    else deferred.resolve!
  deferred.promise

/* Helpers */

getDirs = (folder) ->
  (fs.readdirSync folder).filter (file) ->
    isDirectory (path.join folder, file)

isDirectory = -> (fs.lstatSync it).isDirectory!

clearTerminal = -> process.stdout.write '\u001B[2J\u001B[0;0f'
