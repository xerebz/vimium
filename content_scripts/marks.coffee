
Marks =
  previousPositionRegisters: [ "`", "'" ]
  localRegisters: {}
  mode: null

  exit: (continuation = null) ->
    @mode?.exit()
    @mode = null
    continuation?()

  # This returns the key which is used for storing mark locations in localStorage.
  getLocationKey: (keyChar) ->
    "vimiumMark|#{window.location.href.split('#')[0]}|#{keyChar}"

  getMarkString: ->
    JSON.stringify scrollX: window.scrollX, scrollY: window.scrollY

  setPreviousPosition: ->
    markString = @getMarkString()
    @localRegisters[reg] = markString for reg in @previousPositionRegisters

  showMessage: (message, keyChar) ->
    HUD.showForDuration "#{message} \"#{keyChar}\".", 1000

  # If <Shift> is depressed, then it's a global mark, otherwise it's a local mark.  This is consistent
  # vim's [A-Z] for global marks and [a-z] for local marks.  However, it also admits other non-Latin
  # characters.  The exceptions are "`" and "'", which are always considered local marks.
  isGlobalMark: (event, keyChar) ->
    true

  activateCreateMode: ->
    @mode = new Mode
      name: "create-mark"
      indicator: "Create mark..."
      exitOnEscape: true
      suppressAllKeyboardEvents: true
      keypress: (event) =>
        keyChar = String.fromCharCode event.charCode
        @exit =>
          if @isGlobalMark event, keyChar
            # We record the current scroll position, but only if this is the top frame within the tab.
            # Otherwise, we'll fetch the scroll position of the top frame from the background page later.
            [ scrollX, scrollY ] = [ window.scrollX, window.scrollY ] if DomUtils.isTopFrame()
            chrome.runtime.sendMessage
              handler: 'createMark'
              markName: keyChar
              scrollX: scrollX
              scrollY: scrollY
            , => @showMessage "Created global mark", keyChar
          else
            localStorage[@getLocationKey keyChar] = @getMarkString()
            @showMessage "Created local mark", keyChar

  activateGotoMode: (registryEntry) ->
    @mode = new Mode
      name: "goto-mark"
      indicator: "Go to mark..."
      exitOnEscape: true
      suppressAllKeyboardEvents: true
      keypress: (event) =>
        @exit =>
          keyChar = String.fromCharCode event.charCode
          if @isGlobalMark event, keyChar
            chrome.runtime.sendMessage
              handler: 'gotoMark'
              markName: keyChar
          else
            markString = @localRegisters[keyChar] ? localStorage[@getLocationKey keyChar]
            if markString?
              @setPreviousPosition()
              position = JSON.parse markString
              window.scrollTo position.scrollX, position.scrollY
              @showMessage "Jumped to local mark", keyChar
            else
              @showMessage "Local mark not set", keyChar

root = exports ? window
root.Marks =  Marks
