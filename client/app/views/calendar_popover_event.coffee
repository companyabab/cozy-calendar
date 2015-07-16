PopoverView = require 'lib/popover_view'
Event       = require 'models/event'

module.exports = class EventPopOver extends PopoverView


    # Define the screens. Key is used to switch to screen. Value must be a
    # lib/PopoverScreenView.
    screens:
        main: require 'views/popover_screens/main'
        details: require 'views/popover_screens/details'
        alert: require 'views/popover_screens/alert'
        repeat: require 'views/popover_screens/repeat'


    # Key of the screen that will be shown first.
    mainScreen: 'main'


    # Events delegation. Generic popover controls are handled here.
    events:
        'keyup':                'onKeyUp'
        'click .close':         'selfclose'

        # Used in all the screens to come back to the main screen.
        'click div.popover-back': -> @switchToScreen(@mainScreen)


    initialize: (options) ->

        # If model does not exist, the popover represents a new event.
        if not @model
            @model = new Event
                start: options.start.toISOString()
                end: options.end.toISOString()
                description: ''
                place: ''

        super options


    onKeyUp: (event) ->
        if event.keyCode is 27 # ESC
            @selfclose()


    selfclose: ->
        # Revert if not just saved with addButton.
        if @model.isNew()
            super()
        else
            @model.fetch complete: super

        # Popover is closed so the extended status must be reset.
        window.popoverExtended = false


    close: ->
        # we don't reuse @selfclose because both are doing mostly the same thing
        # but are a little bit different (see parent class).
        # Revert if not just saved with addButton.
        if @model.isNew()
            super()
        else
            @model.fetch complete: super

        # Popover is closed so the extended status must be reset.
        window.popoverExtended = false
