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
  gaze [\src/**/*], ->  @on \all, ->
    invoke \test
  gaze [\test/**/*, ], -> @on \all, ->
    clearTerminal!
    test!
  invoke \test

task \coverage 'Generate code coverage report using jscoverage (saved as coverage.html)' ->
  jscoverage!
    .then ->
      file = fs.createWriteStream \coverage.html
      process.env.\IRCC_COV = 1
      mocha = spawnMocha [\--reporter \html-cov, \test/**/*.ls], false
      mocha.stdout.pipe file
      mocha.on \exit, ->
        spawn \rm [\-r, \lib-cov]
    .catch (error) -> console.error "Unable to generate code coverage report", error

task \cov-badge 'Generate code coverage badge' ->
  try
    badge = require \coverage-badge
  catch
    console.error "Please install 'coverage-badge'"
    process.exit 1

  jscoverage!
    .then ->
      file = fs.createWriteStream \coverage.json
      process.env.\IRCC_COV = 1
      mocha = spawnMocha [\--reporter \json-cov, \test/**/*.ls], false
      mocha.stdout.pipe file
      mocha.on \close, ->
        json = require \./coverage.json
        file = fs.createWriteStream \coverage.png
        badge json.coverage .pipe file
        spawn \rm [\-r, \lib-cov]
    .catch (error) -> console.error "Unable to generate code coverage badge", error

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
  spawnMocha [\--reporter, \spec, \test/**/*.ls, \-G]

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
    deferred = q.defer!
    jscov = spawn \jscoverage ['--no-highlight', 'lib', 'lib-cov'] {stdio: 'inherit'}
    jscov.on \exit (code, signal) ->
      if signal? or code isnt 0 then deferred.reject!
      else deferred.resolve!
    deferred.promise

/* Helpers */

spawnMocha = (args, inheritStdio=true) ->
  path = \node_modules/mocha/bin/mocha
  defaults =
    \-c \--compilers \ls:LiveScript
    \-r \test/common
  args = defaults.concat args
  if inheritStdio then
    mocha = spawn path, args, { stdio: \inherit }
  else
    mocha = spawn path, args

getDirs = (folder) ->
  (fs.readdirSync folder).filter (file) ->
    isDirectory (path.join folder, file)

isDirectory = -> (fs.lstatSync it).isDirectory!

clearTerminal = -> process.stdout.write '\u001B[2J\u001B[0;0f'
