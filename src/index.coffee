###
#!/usr/bin/env node
###
sisig = require './sisig'
___ = require('parkplace').scope sisig
_ = require 'lodash'
chalk = require 'chalk'
hasAnsi = require 'has-ansi'
stripAnsi = require 'strip-ansi'
debug = require('debug') 'sisig-cli'


currentFile = __filename.split('/')
parentDirectory = currentFile.slice(0, -2).join '/'

sisig.databaseLocation = parentDirectory + '/db/cachefile.json'

argv = require('minimist')(process.argv.splice 2)

if argv.w?
    argv.when = argv.w

if argv.tomorrow?
    argv.when = 'tomorrow'

if argv.today?
    argv.when = 'today'
if argv.nextweek?
    argv.when = '1-week'

options = {
    colors: if (argv.colors? or argv.c?) then true else false
    shutup: if (argv.q? or argv.quiet? or argv.shutup? or argv['shut-up']?) then true else false
    terse: if (argv.terse? or argv.t?) then true else false
    json: if (argv.json? or argv.j?) then true else false
    force: if (argv.force? or argv.f?) then true else false
    help: if (argv.help? or argv.h?) then true else null
    verbose: if (argv.verbose?) then true else null
}
if argv.when? or argv.w?
    if argv.when?
        options.when = argv.when
    else
        options.when = argv.w
    if options.when? and _(options.when.split('-')).matchesAnyKey 'week|weeks'.split '|'
            options.when = '7-days'
if options.help?
    console.log JSON.stringify {
        "--tomorrow": "(equivalent to --when=1-day)"
        "--today": "(equivalent to --when=today)"
        "--colors, --c": "boolean"
        "--shutup, --shut-up, --quiet, --q": "boolean"
        "--terse, --t": "boolean"
        "--json, --j": "boolean"
        "--force, --f": "boolean"
        "--when, --w": "string - 'all' (default) / 'today' / 'tomorrow' / '1-day' / '2-days' / '5-day' / '2015-07-21' / '2015-7-21'"
        "--help, --h": "prints this object"
    }, null, 4
    return
if options.json
    options.terse = true
    options.colors = false
if options.terse
    options.shutup = true

if options.verbose?
    sisig.isVerbose = options.verbose

___.readable 'print', (data)->
    afterFirst = false
    if options.json
        return data
    return _(data).map((info)->
        start = "Senor Sisig will be available"
        if afterFirst
            start = _([0..start.length-1]).map(()-> return ' ').value().join('')
        else
            afterFirst = true
        {date, title, location} = info
        if options.colors
            date = chalk.inverse date
            title = chalk.red title
            location = chalk.yellow location
        if info.open
            activeTime = "#{info.time.start} to #{info.time.end}"
            if options.colors
                activeTime = chalk.green activeTime
            if options.terse
                return "#{date} | #{title} | #{location} | #{activeTime}"
            else
                return "#{start} on #{date} at '#{title}' near #{location} from #{activeTime}."
        else
            closed = 'closed'
            if options.colors
                if options.terse
                    closed = closed.toUpperCase()
                closed = chalk.red closed
            if options.terse
                return "#{date} | #{closed}"
            else
                return "Senor Sisig will be #{closed} on #{date}."
        ).value().join '\n'

index = 0
highlight = (str)->
    if index is 0
        pre = ''
        main = str.slice 0, 1
        post = str.slice 1
    else
        pre = str.slice 0, index
        main = str.slice index, index + 1
        post = str.slice index + 1
    if options.colors
        main = chalk.red main
    if index + 1 < str.length
        index += 1
    else
        index = 0
    return pre + main + post

announcement = null
if !options.shutup
    announcement = setInterval ()->
        if process.stdout?.clearLine?
            process.stdout.clearLine()
        if process.stdout?.cursorTo?
            process.stdout.cursorTo(0)
        process.stdout.write highlight "Loading the burrito data... "
    , 100

stopAnnouncing = ()->
    if announcement?
        clearInterval announcement
        if process.stdout?.clearLine?
            process.stdout.clearLine()
        if process.stdout?.cursorTo?
            process.stdout.cursorTo(0)
        process.stdout.write "  \n"

ready = ()->
    stopAnnouncing()
    console.log sisig.print sisig.filterByDate options.when
    if sisig.cachefile.staleData or !sisig.cachefile.hasFile or options.force
        good = ()->
            debug "exiting..."
            process.exit()
        bad = (e)->
            console.log "Error writing cachefile.", e
            process.exit()
        sisig.writeCache().then good, bad
    setTimeout ()->
        process.exit()
    , 10000


fail = ()->
    stopAnnouncing()
    console.log "Fail is the best!", arguments

if options.force
    sisig.loadFromWeb().then ready, fail
else
    sisig.load().then ready, fail