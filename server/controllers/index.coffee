async = require 'async'
moment = require 'moment'
cozydb = require 'cozydb'
log = require('printit')
    date: true
    prefix: 'calendar:client'

Tag = require '../models/tag'
Event = require '../models/event'
Sharing = require '../models/sharing'
Contact = require '../models/contact'
User  = require '../models/user'
WebDavAccount = require '../models/webdavaccount'
Settings  = require '../models/settings'


module.exports.index = (req, res, next) ->
    async.parallel [
        (done) -> Contact.all (err, contacts) ->
            return done err if err
            for contact, index in contacts
                contacts[index] = contact.asNameAndEmails()
            done null, contacts

        (cb) -> Tag.byName {}, cb
        (cb) -> Settings.getCalAppSettings cb
        (cb) -> Event.calendars cb
        # Load only reccuring events and events close to current day (> -3
        # months and < +3 months). That way it doesn't load too much events.
        (cb) ->
            start = moment().startOf('month').subtract 3, 'months'
            end = moment().endOf('month').add 3, 'months'
            Event.load start, end, (err, events) ->
                Event.request 'reccuring', (err, reccuringEvents) ->
                    cb null, events?.concat reccuringEvents
        (cb) -> Sharing.pendingBySharedDocType 'event', cb
        (cb) -> cozydb.api.getCozyInstance cb
        (cb) -> WebDavAccount.first cb
        (cb) ->

            # Handle the case there User.timezone data is not cached yet.
            if User.timezone?
                cb null, User.timezone

            else
                User.updateUser ->
                    cb null, User.timezone


    ], (err, results) ->

        return next err if err


        [
            contacts, tags, settings, calendars, events, pendingEventSharings, instance,
            webDavAccount, timezone
        ] = results

        locale = instance?.locale or 'en'
        if webDavAccount?
            webDavAccount.domain = instance?.domain or ''

        timezone = timezone or 'UTC'

        # Objects returned by the database may contain characters that need to
        # be escaped to prevent error in some browsers
        sanitize = (obj) ->
            return """
              JSON.parse(decodeURI("#{encodeURI(JSON.stringify(obj))}"));
            """

        res.render 'index', imports: """
            window.locale = "#{locale}";
            window.inittags = #{sanitize tags};
            window.initcalendars = #{sanitize calendars};
            window.initevents = #{sanitize events}
            window.initPendingEventSharings = #{sanitize pendingEventSharings};
            window.initcontacts = #{sanitize contacts};
            window.initsettings = #{sanitize settings};
            window.webDavAccount = #{sanitize webDavAccount};
            window.timezone = #{sanitize timezone};
        """

module.exports.logClient = (req, res) ->
    log.error req.body.data
    log.error req.body.data.error?.stack
    res.send 'ok'

