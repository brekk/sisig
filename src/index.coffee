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
    return  d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate()

dateSplitter = (dString)->
    parts = dString.split '-'
    return {
        month: parts[1] - 1
        date: parts[2]
        year: parts[0]
    }

timeValidator = (givenTime)->
    d = new Date()
    if givenTime is 'tomorrow'
        d.setDate(d.getDate() + 1)
    if givenTime.indexOf('-') isnt -1
        {month, date, year} = dateSplitter givenTime
        d.setDate date
        d.setMonth month
        d.setYear year
    # if givenTime is 'today' or givenTime is 'now'
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
        process.stdout.clearLine()
        process.stdout.cursorTo(0)
        process.stdout.write highlight "Loading the burrito data... "
    , 100

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
    stale = 200000
    now = Date.now()
    diff = Math.abs now - cache['last-called']
    # console.log """
    # comparing right now: #{now} (#{new Date(now)}
    #               cache: #{cache['last-called']}
    #                diff: #{diff}
    #              larger: #{diff > stale}
    # """
    return diff > stale

crawlback = _.once (e, res, $)->
    if e?
        console.log "Error during crawling", e
        if e.stack?
            console.log e.stack
        return
    setTimeout timeOutKill, 10000
    if announcement?
        clearInterval announcement
        process.stdout.clearLine()
        process.stdout.cursorTo(0)
        process.stdout.write "  \n"
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
                title = active.find('h5').eq(0).text()
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
                }
                whatDay = data.date
                if options.colors
                    whatDay = chalk.inverse whatDay
                    title = chalk.red title
                    location = chalk.yellow location
                    activeTime = chalk.green activeTime
                unless options.terse
                    start = "Senor Sisig will be available"
                    if afterFirst
                        start = "                             "
                    if dateValid
                        console.log "#{start} on #{whatDay} at \"#{title}\" near #{location} from #{activeTime}."
                else
                    unless options.json
                        if dateValid
                            console.log "#{whatDay} | #{title} | #{location} | #{activeTime}"
                output.push data
                if dateValid
                    afterFirst = true
                return
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
                    process.exit()
                    return
                console.log "Error during attempted file writing.", e
                process.exit()
                return
        else
            unless options.terse
                console.log "Not writing output to cachefile."
            process.exit()
    return
if hasData and !readyNow()
    raw = cache.raw
    $ = cheerio.load raw, {
        normalizeWhitespace: false
        decodeEntities: true
    }
    crawlback null, raw, $
else
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