_ = require './yolodash'
fs = require 'fs'
moment = require 'moment'
pp = require 'parkplace'

Crawler = require 'crawler'

prettyHTML = require('js-beautify').html

# promise = require 'promised-io/promise'
Promise = require 'bluebird'
# pfs = require 'promised-io/fs'
pfs = Promise.promisifyAll fs

Model = require 'ampersand-model'
debug = require('debug') 'sisig'
verbose = require('debug') 'sisig-verbose'
j4 = ->
    return _.map arguments, (arg)->
        return JSON.stringify arg, null, 4

Sisig = {}
___ = pp.scope Sisig

___.mutable 'staleDataThreshold', 72e5
___.mutable 'databaseLocation', 'cachefile.json'

Cachefile = Model.extend {
    session:
        hasFile: ['boolean', true, false]
        isVerbose: ['boolean', true, false]

    props: 
        lastCalled: 
            type: 'number'
            required: true
            default: ()->
                return Date.now()
        dates:
            type: 'array'
            required: true
        lastScrape:
            type: 'string'
            required: false
            default: ''

    derived:
        verbose:
            deps: [
                'isVerbose'
            ]
            cache: false
            fn: ->
                if @isVerbose?
                    return verbose
                return ->
        calendar:
            deps: [
                'dates'
            ]
            cache: true
            fn: ()->
                return _ @dates
        staleData:
            deps: [
                'lastCalled'
            ]
            cache: false
            fn: ()->
                now = Date.now()
                debug "%s - %s", @lastCalled, now
                diff = Math.abs @lastCalled - now
                truth = diff > Sisig.staleDataThreshold
                debug '%s = %s > %s', truth, diff, Sisig.staleDataThreshold
                debug "diff: %s, stale? %s", diff, truth
                return truth


    filterByDate: (givenTime='all')->
        debug 'filtering by date, given: %s', givenTime
        d = new Date()
        if givenTime?
            if givenTime instanceof Date
                d = givenTime
            else if _.isString givenTime
                if givenTime is 'all'
                    return @calendar.value()
                else if givenTime is 'today'
                    d.setDate d.getDate()
                else if givenTime is 'tomorrow'
                    d.setDate d.getDate() + 1
                else if givenTime.indexOf('-') isnt -1
                    hyphenated = givenTime.split '-'
                    if hyphenated.length is 3
                        d = Sisig.parseDate givenTime
                    else if _(hyphenated).matchesAnyKey 'days|day'.split '|'
                        days = parseInt _.first hyphenated
                        d = new Date moment(d).add days, 'days'
        matching = {
            date: Sisig.formatDate d
        }
        debug 'looking to match: %s', matching.date.toString()
        return @calendar.where matching
                        .value()
}

___.readable 'formatDate', (d, verbose=false)->
    if _.isNumber d
        d = new Date d
    if d instanceof Date
        if verbose
            return moment(d).format 'YYYY[-]MM[-]DD[ ]HH:mm:ss'
        return moment(d).format 'YYYY[-]MM[-]DD'
    return false

___.readable 'parseDate', (str)->
    d = new Date()
    parts = str.split '-'
    d.setMonth parts[1] - 1
    d.setDate parts[2]
    d.setYear parts[0]
    return d

___.mutable 'cachefile', new Cachefile()

_.each [
    'on'
    'once'
    'trigger'
    'off'
    'filterByDate'
], (method)->
    ___.readable method, ()->
        Sisig.cachefile[method].apply Sisig.cachefile, arguments
    debug 'creating `%s` method', method, Sisig[method]?

___.constant 'consume', (input)->
    if input?.lastScrape?
        @cachefile.lastScrape = input.lastScrape
    if input?.lastCalled?
        @cachefile.lastCalled = input.lastCalled
    if input?.dates?
        @cachefile.dates = input.dates
        @trigger 'loaded', @

___.readable 'writeFile', (file, output, json=true)->
    debug 'planning to write to file: %s %s', file, if json then "(json)" else ''
    return new Promise (fulfill, reject)->
        good = ()->
            fulfill true
            debug 'wrote to file.'
            return
        bad = (e)->
            reject e
            debug 'failed to write to file.'
            return
        if json
            debug 'converting to json.'
            output = JSON.stringify output, null, 4
        pfs.writeFileAsync(file, output).then good
                                        .catch bad

___.readable 'readFile', (filename, json=true)->
    debug 'planning to read from file: %s %s', filename, if json then "(json)" else ''
    return new Promise (fulfill, reject)->
        file = pfs.readFileAsync filename, {
            charset: 'utf8'
        }
        good = (input)->
            output = input.toString()
            if !output? or output.length is 0
                reject new Error "File is empty."
                return
            if json
                output = JSON.parse output
            fulfill output
        file.then good
            .catch reject
        return d

___.readable 'parse', (e, res, $)->
    try
        debug 'parsing...'
        return new Promise (fulfill, reject)->
            self = Sisig
            if e?
                console.log "error during parsing", e
                if e.stack?
                    console.log e.stack
                reject e
                return
            if res?.body?
                debug "res.body available..."
                Sisig.cachefile.lastScrape = res.body
            else
                debug "res available..."
                Sisig.cachefile.lastScrape = res
            scrape = ()->
                try
                    debug "scraping..."
                    sections = $('#find-us').find "section:not([data-wcal-date=error])"
                    output = []
                    sections.each ()->
                        section = $ @
                        rawDateData = section.attr 'data-wcal-date'
                        relativeDate = self.parseDate rawDateData
                        rows = section.find '.map-row'
                        rows.each ()->
                            active = $ @
                            title = active.find 'h5'
                                          .eq 0
                                          .text()
                                          .trim()
                            location = active.find '.map-trigger'
                                             .text()
                                             .split '. ,'
                                             .join ','
                            activeTime = active.find '.time'
                                               .text()
                                               .trim()
                            activeTime = _(activeTime.split('\n')).map((word)->
                                return word.trim()
                            ).value().join(' ')
                            data = {
                                date: self.formatDate relativeDate
                                title: title
                                open: if location.length isnt 0 then true else false
                            }
                            if data.open
                                data.location = location
                                time = activeTime.split ' to '
                                data.time = {
                                    start: time[0]
                                    end: time[1]
                                }
                                convertToFullTime = (time)->
                                    moment time, 'HH:mm[ ]a'
                                time[0] = Number convertToFullTime time[0]
                                time[1] = Number convertToFullTime time[1]
                                data.pedanticTime = {
                                    start: self.formatDate time[0], true
                                    end: self.formatDate time[1], true
                                }
                            output.push data
                            self.cachefile.verbose j4 data
                            return
                        return
                    self.consume {dates: output}
                    fulfill output
                    return
                catch e
                    reject e
            scrape()
            return

___.readable 'crawler', _.once ()->
    crawler = new Crawler {
        maxConnections: 1
        jQuery:
            name: 'cheerio'
            options:
                normalizeWhitespace: true
        callback: Sisig.parse
    }
    debug "generating crawler instance... %s", j4 crawler
    return crawler

___.readable 'loadFromWeb', ()->
    debug "loading content from web..."
    self = Sisig
    return new Promise (fulfill, reject)->
        self.once 'error:parse', (e)->
            reject e
        self.once 'loaded', ()->
            fulfill self
        self.crawler().queue 'http://senorsisig.com'
        return

___.readable 'loadFromFile', (filename)->
    debug "loading content from cache..."
    self = Sisig
    return new Promise (fulfill, reject)->
        bad = (error)->
            reject error
        good = (input)->
            self.consume input
            fulfill Sisig
        return pfs.readFileAsync(filename).then good
                                          .catch bad

___.readable 'load', ()->
    self = Sisig
    return new Promise (fulfill, reject)->

        self.once 'error:parse', (e)->
            reject e

        self.once 'loaded', ()->
            fulfill self

        rescrape = self.loadFromWeb

        good = ()->
            # we have a file, so we can infer staleness
            self.cachefile.hasFile = true
            if self.cachefile.staleData
                fulfill rescrape()
            else
                console.log self, "<<<< self"
                fulfill self
        alreadyBad = false
        bad = (e)->
            console.log "error during load", e
            if e?
                reject e



        return self.loadFromFile(self.databaseLocation).then good, bad
                                                       .catch bad

___.readable 'writeCache', ()->
    self = Sisig
    self.cachefile.lastCalled = Date.now()
    return self.writeFile self.databaseLocation, self.cachefile.toJSON()

module.exports = Sisig