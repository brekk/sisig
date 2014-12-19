###
#!/usr/bin/env node
###
Crawler = require 'crawler'
url = require 'url'
_ = require 'lodash'
cheerio = require 'cheerio'
chalk = require 'chalk'
prettyHTML = require('js-beautify').html
fs = require 'fs'
moment = require 'moment'
hasAnsi = require 'has-ansi'
stripAnsi = require 'strip-ansi'

currentFile = __filename.split('/')
parentDirectory = currentFile.slice(0, -2).join '/'

argv = require('minimist')(process.argv.splice 2)

hasData = false
cache = {
    "last-called": Date.now()
}
cachefile = parentDirectory + '/db/cache.json'
try
    cache = require cachefile
    if cache?
        hasData = true
    # console.log "cachefile found."
catch e
    console.log "no cachefile found."

if argv.tomorrow?
    argv.when = 'tomorrow'

if argv.today?
    argv.when = 'today'

options = {
    colors: if argv.colors? then argv.colors else false
    shutup: if (argv.q? or argv.quiet? or argv.shutup?) then true else false
    terse: if argv.terse? then argv.terse else false
    json: if argv.json? then argv.json else false
    force: if (argv.force? or argv.f?) then true else false
    when: if argv.when? then argv.when else 'all'
}
if options.json
    options.terse = true
    options.colors = false
if options.terse
    options.shutup = true

formatDate = (d)->
    return moment(d).format 'YYYY[-]MM[-]DD'

dateSplitter = (dString)->
    parts = dString.split '-'
    return {
        month: parts[1] - 1
        date: parts[2]
        year: parts[0]
    }

timeValidator = (givenTime)->

    d = new Date()
    if givenTime? and _.isString givenTime
        if givenTime is 'tomorrow'
            d.setDate(d.getDate() + 1)

        if givenTime.indexOf('-') isnt -1

            hyphenated = givenTime.split('-')
            if hyphenated.length is 3
                {month, date, year} = dateSplitter givenTime
                d.setDate date
                d.setMonth month
                d.setYear year
            else if _.contains hyphenated, 'days'
                days = Number _.first hyphenated
                d = new Date moment(d).add(days, 'days')
            else if _.contains hyphenated, 'day'
                d = new Date moment(d).add(1, 'days')

    
    return d

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
if !options.shutup or hasData
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

forceZeroes = (n)->
    if _.isNumber(n) and n < 10
        return '0' + n
    return '' + n

timeOutKill = ()->
    fail = "Unable to ascertain where the burritos at."
    if options.colors
        fail = chalk.red fail
    console.log fail
    process.exit()

readyNow = ()->
    stale = 72e5
    now = Date.now()
    diff = Math.abs now - cache['last-called']
    return diff > stale

crawlback = _.once (e, res, $)->
    if e?
        console.log "Error during crawling", e
        if e.stack?
            console.log e.stack
        return
    setTimeout timeOutKill, 10000
    stopAnnouncing()
    unless options.terse
        console.log ""
    writeWhenDone = readyNow()
    if writeWhenDone
        # because we use the crawlback method in multiple ways and we don't store the original res
        if res.body?
            cache.raw = prettyHTML res.body
        else
            cache.raw = res
    scrapeAndRead = (cb)->
        sections = $('#find-us').find("section:not([data-wcal-date=error])")
        output = []
        afterFirst = false
        sections.each ()->
            section = $ @
            rawDateData = section.attr('data-wcal-date')
            dateValid = false
            if options.when isnt 'all'
                validatedDate = formatDate timeValidator options.when
                dateValid = rawDateData is validatedDate
            else
                dateValid = true
            dateParts = rawDateData.split '-'
            relativeDate = new Date dateParts[0], dateParts[1]-1, dateParts[2]
            rows = section.find('.map-row')
            rows.each ()->
                active = $ @
                title = active.find('h5').eq(0).text().trim()
                location = active.find('.map-trigger').text().split('. ,').join(',')
                activeTime = active.find('.time').text().trim()
                activeTime = _(activeTime.split('\n')).map((word)->
                    return word.trim()
                ).value().join(' ')
                time = activeTime.split ' to '
                data = {
                    date: formatDate relativeDate
                    title: title
                    location: location
                    time: {
                        start: time[0]
                        end: time[1]
                    }
                    open: true
                }
                whatDay = data.date
                theBestPlace = "Senor Sisig"
                if options.colors
                    whatDay = chalk.inverse whatDay
                    title = chalk.red title
                    location = chalk.yellow location
                    activeTime = chalk.green activeTime
                    place = theBestPlace.split ' '
                    place[0] = chalk.yellow place[0]
                    place[1] = chalk.cyan place[1]
                    theBestPlace = chalk.bgRed place.join ' '

                start = "#{theBestPlace} will be available"
                if location.length is 0
                    strongNot = 'not'
                    if options.colors
                        strongNot = chalk.red strongNot
                    start = "#{theBestPlace} will #{strongNot} be available"
                else 
                    if afterFirst
                        if hasAnsi start
                            temp = stripAnsi start
                        else
                            temp = start
                        start = _([0..temp.length-1]).map(()-> return ' ').value().join('')
                if location.length isnt 0
                    unless options.terse
                        if dateValid
                            console.log "#{start} on #{whatDay} at \"#{title}\" near #{location} from #{activeTime}."
                    else
                        unless options.json
                            if dateValid
                                console.log "#{whatDay} | #{title} | #{location} | #{activeTime}"
                else
                    if dateValid
                        unless options.terse
                            console.log "#{start} on #{whatDay}."
                        else
                            unless options.json
                                closed = 'CLOSED'
                                if options.colors
                                    closed = chalk.red closed
                                console.log "#{whatDay} | #{closed}"
                    data.open = false
                    delete data.time
                    delete data.location

                output.push data
                if dateValid
                    afterFirst = true
                return
        if output?
            # restructure the data to be easily parsed
            output = _(output).groupBy('date').value()
        if options.json
            process.stdout.write JSON.stringify output
        if writeWhenDone
            cache.data = output
        if cb? and _.isFunction cb
            cb()
        return
    scrapeAndRead ()->
        if !hasData or writeWhenDone or options.force
            unless options.terse
                console.log "Writing output to cachefile."
            cache['last-called'] = Date.now()
            output = JSON.stringify cache, null, 4
            # console.log "normally we would write the output, but it's borked!"
            # console.log "this is what we would write: \n"
            # console.log output
            fs.writeFile cachefile, output, 'utf8', (err)->
                unless err
                    unless options.terse
                        console.log "Done!"
                    else
                        console.log ""
                    process.exit()
                    return
                console.log "Error during attempted file writing.", e
                process.exit()
                return
        else
            unless options.terse
                console.log "Not writing output to cachefile."
            else
                console.log ""
            process.exit()
    return

crawl = ()->
    c = new Crawler
        maxConnections: 1
        jQuery: {
            name: 'cheerio'
            options: {
                normalizeWhitespace: false
            }
        }
        callback: crawlback
    c.queue 'http://senorsisig.com'
    
if options.force
    crawl()
else
    if hasData and !readyNow()
        raw = cache.raw
        $ = cheerio.load raw, {
            normalizeWhitespace: false
            decodeEntities: true
        }
        crawlback null, raw, $
    else
        crawl()