{spawn} = require \child_process
badge = require \coverage-badge
require! [\gaze \fs]

/* Tasks */

task \build 'Compile all LiveScript from src/ to JavaScript in lib/' ->
  clean ->
    build!

task \test 'Run the tests' ->
  build ->
    runMocha [\--reporter, \spec, \test/**/*.ls, \-G]

task \justtest 'Run the tests without running "build"' ->
  runMocha [\--reporter, \spec, \test/**/*.ls]

task \watch 'Watch, compile and test files.' ->
  run = (task) -> (->
      clearTerminal!
      invoke task)
  gaze [\src/*], ->  @on \all, run \test
  gaze [\test/*], -> @on \all, run \justtest
  (run 'test')!

task \coverage 'Generate code coverage report using jscoverage (saved as coverage.html)' ->
  jscoverage (code, signal) ->
    file = fs.createWriteStream \./coverage.html
    process.env.\AETHER_COV = 1
    mocha = runMocha [\--reporter \html-cov], false
    mocha.stdout.pipe file
    mocha.on \exit, ->
      spawn \rm [\-r, \lib-cov]

task \cov-badge 'Generate code coverage badge' ->
  jscoverage (code, signal) ->
    file = fs.createWriteStream \./coverage.json
    process.env.\AETHER_COV = 1
    mocha = runMocha [\--reporter \json-cov], false
    mocha.stdout.pipe file
    mocha.on \close, ->
      json = require \./coverage.json
      file = fs.createWriteStream \./coverage.png
      badge json.coverage .pipe file
      spawn \rm [\-r, \lib-cov]

/* Helper functions */

clean = (cb) ->
  proc = spawn \rm [\-r \./lib]
  if cb then proc.on \exit cb

build = (cb) ->
  livescript [\-bco \lib] ++ ["src/#file" for file in dir \src when /\.ls$/.test file], cb

livescript = (args, cb) ->
  proc = spawn \livescript args
  proc.stderr.on \data say
  proc.on \exit, (err) ->
    if err then process.exit err
    if cb then cb!

runMocha = (args, inheritStdio=true) ->
  path = \node_modules/mocha/bin/mocha
  defaults =
    \-c \--compilers \ls:LiveScript
    \-r \test/common
  args = defaults.concat args
  if inheritStdio then
    mocha = spawn path, args, { stdio: \inherit }
  else
    mocha = spawn path, args

jscoverage = (callback) ->
  build ->
    jscov = spawn \jscoverage ['--no-highlight', 'lib', 'lib-cov'] {stdio: 'inherit'}
    jscov.on \exit (code, signal) ->
      if signal? or code isnt 0 then process.exit code
      else callback!

clearTerminal = -> process.stdout.write '\u001B[2J\u001B[0;0f'
