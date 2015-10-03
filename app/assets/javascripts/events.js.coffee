# ########## # ########
# ########## # ######
# ########## # ####
# EventModel # ##
# ########## #
# ########## #
# ########## #

class window.EventModel
  # Public #
  constructor: (@attributes = {}) ->

  @all: (async, keys) => @_ajax.all async, keys
  @create: (attributes) => @_ajax.create attributes
  @destroy: (id) => @_ajax.destroy id
  @update: (attributes) => @_ajax.update attributes
  @count: (async, search_key, mine) => @_ajax.count async, search_key, mine

  destroy: => @_ajax.destroy @attributes.id
  update: (attributes) => @_ajax.update attributes

  template: ->
    htmlRender = "
      <div class='event'>
        <div class='event-content'>
          <div class='date-time'>
            <center>
              <div class='time'>{{ @time }}</div>
              <div class='date'>{{ @date }}</div>
            </center>
          </div>
          <div class='content'>
            <div class='title'>{{ @title }}</div>
            <div class='description'>{{ @description }}</div>
          </div>
          <div class='author'>
            <center>
              <p>Author</p>
              <p>{{ @author }}</p>
            </center>
          </div>
        </div>
        {{ @@tools }}
      </div>"
    if !UserModel.currentUser || @attributes.user_id != UserModel.currentUser.id then return htmlRender.replace "{{ @@tools }}", ""
    isLocked = unless @attributes.secret then "Lock" else "Unlock"
    htmlRender = htmlRender.replace "{{ @@tools }}", "
    <div class='tools'>
      <div class='edit'><a class='edit_event' event_id='#{@attributes.id}'>Edit</a></div>
      <div class='lock'><a class='lock_event' event_id='#{@attributes.id}'>#{isLocked}</a></div>
      <div class='destroy'><a class='destroy_event' event_id='#{@attributes.id}'>Destroy</a></div>
    </div>"
    htmlRender
  getTemplate: ->
    parsedTmp = @template()
    jQuery.each @attributes, (attr, val) ->
      # parsedTmp = parsedTmp.replace new RegExp("{{\s*@#{attr}\s*}}", 'g'), val
      re = new RegExp("{{\\s*@#{attr}\\s*}}", "g")
      parsedTmp = parsedTmp.replace re, val
    parsedTmp.replace /{{\s*@\w*\s*}}/g, ''
  toString: => do @getTemplate

  @objectContainerToEventModelContainer: (container) ->
    returnEvents = []
    for e in [0...container.length]
      returnEvents.push new EventModel container[e]
    return returnEvents

  # Private #

  @_ajax:
    objectContainerToEventModelContainer: @objectContainerToEventModelContainer
    send: (data) ->
      jQuery.ajax data
    create: (attributes) ->
      @send type: "POST", url:  "events", data: attributes
    all: (async = false, keys) ->
      events = {}
      ajax = @send type: "GET", url: "events", dataType: "json", data: keys, async: async, success: (data) ->
        events = data
      if !async
        return @objectContainerToEventModelContainer events
      ajax
    destroy: (id) ->
      @send type: "DELETE", url: "/events/#{id}"
    update: (attributes) ->
      @send type: "PUT", url: "events/#{attributes.id}", data: attributes
    count: (async = false, search_key = "", mine = false) ->
      c = 0
      ajax = @send type: "GET", url: "events", dataType: "json", data: { search_key: search_key, mine: mine, count: true }, async: async, success: (data) ->
        c = data.count
      if !async
        return c
      ajax
  _ajax: @_ajax

# ################# # ########
# ################# # ######
# ################# # ####
# createEventDialog # ##
# ################# #
# ################# #
# ################# #

window.createEventDialog =
  init: ->
    do @_setDefaults
    this
  show: (attributes) ->
    do @formForCreateEventOverlay.fadeIn
    do jQuery("#overlayOpacity").fadeIn
    if attributes != undefined
      @_idForUpdate = attributes["id"]
      jQuery.each attributes, (attr, val) ->
        $obj = jQuery("#new_event_#{attr}")
        if $obj.attr("type") == "checkbox" then $obj.prop("checked", val) else $obj.val(val)
        $obj.trigger "change"; $obj.trigger "keyup"
  hide: ->
    do @formForCreateEventOverlay.fadeOut
    do jQuery("#overlayOpacity").fadeOut
  getAjaxData: ->
    data = {
      event:
        title: @inputs.title
        description: @inputs.description
        being_at: "#{@inputs.date} #{@inputs.time}"
        secret: @inputs.secret
    }
    data["id"] = @_idForUpdate if @_idForUpdate != undefined
    data
  clearData: ->
    delete @_idForUpdate
    hashToSet = do @initialValues
    jQuery.each jQuery("#formForCreateEventOverlay input"), (attr, val) ->
      $obj = jQuery(val)
      attr = $obj.attr("id").replace "new_event_", ""
      if $obj.attr("type") == "checked" then $obj.prop("checked", hashToSet[attr]) else $obj.val(hashToSet[attr])
  initialValues:->
    { title: "", description: "", date: "", time: "", secret: false }
  # private
  _setDefaults: ->
    @inputs = do @initialValues
    do @_setCallbacks
    @formForCreateEventOverlay = jQuery "#formForCreateEventOverlay"
  _cbOnIputChange: (that, $obj) ->
    action = $obj.attr("id").replace "new_event_", ""
    if $obj.attr("type") == "checkbox"
      that.inputs[action] = $obj.is(":checked"); return
    that.inputs[action] = do $obj.val
  _setCallbacks: ->
    that = this; link = @_cbOnIputChange
    cb = -> link that, jQuery(this)
    jQuery("#formForCreateEventOverlay input").change(cb).keyup(cb)
    jQuery(save_event).click( => do @_saveClicked).click => do controller.refreshEvents
  _saveClicked: ->
    cb = => do @getAjaxData
    ajax = if @_idForUpdate != undefined then EventModel.update do cb else EventModel.create do cb
    ajax.fail(controller.ajaxFailed).success (data) ->
      notice.show data.status, if data.message then data.message else data.errors
    do @clearData

# ############# # ########
# ############# # ######
# ############# # ####
# window.notice # ##
# ############# #
# ############# #
# ############# #

window.notice =

  init: ->
    @message = ""
    @$body = jQuery("#notice")

  show: (@status = "success", message = "") ->
    if @status == "success" then @showNotice message else @showAlert message
  showNotice: (@message = "") ->
    do @showDefaults
  showAlert: (@message = "") ->
    @showDefaults true
  showDefaults: (alert = false) ->
    do @arrayToString
    do @setBody
    do @setCSS
    @$body.css if alert then color: "red" else color: "#000"
    do @setDefaultMarginTop
    do @setVisible
    do @hide
  hide: ->
    @setVisible false

  arrayToString: ->
    if @message instanceof Array
      errors = @message; parsedErrors = ""
      for i in [0...errors.length]
        parsedErrors += "<li>#{errors[i]}</li>"
      @message = "<ul>#{parsedErrors}</ul>"

  setCSS: ->
    @$body.css marginLeft: ((jQuery("#body").width() - 300) / 2)
  marginTop: ->
    +"-#{do @$body.height + 60}"
  setDefaultMarginTop: ->
    @$body.css marginTop: do @marginTop

  body: -> "<p>{{ @message }}</p>"
  setBody: ->
    @$body.html this + ""
  setVisible: (visibility = true) ->
    marginTop = if visibility then 10 else do @marginTop
    @$body.animate marginTop: marginTop, 1200

  toString: ->
    @body().replace "{{ @message }}", @message


# ################ # ########
# ################ # ######
# ################ # ####
# EventsController # ##
# ################ #
# ################ #
# ################ #

window.controller = window.eventsController =

  # public

  init: ->
    do @_setDefaults
    do @refreshEvents
  refreshEvents: ->
    jQuery(events).html "<h1>Data's refreshing ...</h1>"
    ajax = EventModel.all true, @searchData
    ajax.success (data) => @setEventsOnPage data
  eventsRender: (data = @events) ->
    @events = EventModel.objectContainerToEventModelContainer data
    do @updatePagesNav
    eventsRender = ""
    jQuery.each @events, (index, val) ->
      eventsRender += do val.toString
    eventsRender
  setEventsOnPage: (data = @events) ->
    if data.length == 0 && @searchData.offset != 0
      @searchData.offset--
      return do @refreshEvents
    jQuery(events).html @eventsRender data
    do @updateCallbacks
  getSearchData: ->
    {
      limit: @searchData.limit
      offset: @searchData.offset
      search_key: do jQuery(search_key).val
      mine: @searchData.mine
    }
  updatePagesNav: ->
    eventsCount = EventModel.count false, @searchData.search_key, @searchData.mine
    pages = eventsCount / @searchData.limit
    parsedIntPages = parseInt pages
    if pages > parsedIntPages
      pages++
    else
      pages = parsedIntPages
    pagesHtml = ""
    if pages > 0
      for i in [1..pages]
        pagesHtml += "<button {{ @@isCurrentPage }} page_number='#{i-1}'>#{i}</button>"
        pagesHtml = pagesHtml.replace "{{ @@isCurrentPage }}",
          if i == +@searchData.offset + 1 then "class='silver-button'" else ""
    jQuery(pagesLinker).html pagesHtml
    do @updatePagesNavCallbacks
  updatePagesNavCallbacks: ->
    that = this
    jQuery("#pagesLinker *").click => do @updatePagesNav
    jQuery("#pagesLinker *").click ->
      that.searchData.offset = jQuery(this).attr('page_number')
  updateCallbacks: ->
    that = this
    jQuery("#pagesLinker *").click => do @refreshEvents
    jQuery(".destroy_event").click ->
      e = new EventModel { id: jQuery(this).attr "event_id" }
      e.destroy().success((data) => that._showNotice(data)).success( => do that.refreshEvents).fail => do that.ajaxFailed
    jQuery(".edit_event").click ->
      event = that.findIndexOfEventsOnPageById +jQuery(this).attr("event_id")
      createEventDialog.show event.attributes
    jQuery(".lock_event").click ->
      a = that.findIndexOfEventsOnPageById(+jQuery(this).attr("event_id")).attributes
      update = id: a.id, event: { title: a.title, description: a.description, being_at: a.being_at, secret: !(a.secret) }
      EventModel.update(update).fail( => do that.ajaxFailed).success((data) => that._showNotice(data)).success( => do that.refreshEvents)
  findIndexOfEventsOnPageById: (id) ->
    for i in [0...@events.length]
      return @events[i] if @events[i].attributes.id == id
  ajaxFailed: (data) ->
    notice.show "failure", data.responseText

  # private

  _setDefaults: ->
    do @_setDefaultCallBacks
    do @_setCallbacksForCreating
    @searchData = limit: 7, offset: 0, mine: false
  _showNotice: (data) ->
    notice.show data.status, if data.message then data.message else data.errors
  _setCallbacksForCreating: ->
    dialog = createEventDialog
    jQuery(close_formForCreateEventOverlay).click( => do dialog.hide).click => do dialog.clearData
    jQuery(show_form_for_new_event).click( => do dialog.show)
    jQuery(save_event).click => do dialog.hide
  _setDefaultCallBacks: ->
    that = this
    jQuery(show_all_events).click ->
      that.searchData.mine = false
    jQuery(show_my_events).click ->
      that.searchData.mine = true
    jQuery("#search_button, #show_all_events, #show_my_events").click( => do @refreshEvents).click => do @updatePagesNav
    jQuery(search_key).keypress (e) ->
      if e.keyCode == 13
        do jQuery(search_button).click
    jQuery("#formForCreateEventOverlay input").keypress (e) ->
      if e.keyCode == 13
        do jQuery("#save_event").click
    jQuery(search_key).keyup ->
      that.searchData.search_key = do jQuery(this).val

# ############## # ########
# ############## # ######
# ############## # ####
# userController # ##
# ############## #
# ############## #
# ############## #

window.userController =
  init: ->

# ######### # ########
# ######### # ######
# ######### # ####
# UserModel # ##
# ######### #
# ######### #
# ######### #

class window.UserModel
  @init: ->
    do @updateCurrentUser
  controller: ->
  @updateCurrentUser: ->
    that = this
    jQuery.ajax(type: "GET", url: "../../events/current_user_data.json").success (data) ->
      that.currentUser = data
      jQuery("#signLinks").trigger "show"

# ###################### # ########
# ###################### # ######
# ###################### # ####
# when document is ready # ##
# ###################### #
# ###################### #
# ###################### #

jQuery(document)

  .on "ready page:load", => do notice.init
  .on "ready page:load", => do UserModel.init
  .on "ready page:load", => do userController.init

  .on "ready page:load", ->
    showBar = (bar, bool = true) ->
      methodName = if bool then "show" else "hide"
      jQuery("##{bar}Bar")[methodName]()
    hideBar = (bar) => showBar bar, false

    hideBar "user"

    jQuery("#signLinks")
      .on "showSignBar", ->
        hideBar "user"; showBar "sign"
      .on "showUserBar", ->
        hideBar "sign"; showBar "user"
      .on "show", ->
        if UserModel.currentUser
          jQuery(@).trigger "setUserName"
        else
          jQuery(@).trigger "showSignBar"
      .on "setUserName", (event, userName = UserModel.currentUser.full_name) ->
        jQuery("#userBar").children().html userName
        jQuery(@).trigger "showUserBar"

  .on "ready page:load", -> 
    do resizeElements

  .on "ready page:load", ->
    showUserInformation = (bool = true) ->
      visibility = if bool then "fadeIn" else "fadeOut"
      do jQuery("#currentUserInformationOverlay")[visibility]
      do jQuery("#overlayOpacity")[visibility]

    jQuery("#show_currentUserInformation").click ->
      do showUserInformation

    jQuery("#close_currentUserInformation, #log_out_current_user").click ->
      showUserInformation false

  .on "ready page:load", ->
    jQuery("#log_out_current_user")
      .on "ajax:success", (data) ->
        notice.showAlert "You've successally Signed Out!"
        do UserModel.updateCurrentUser
        do controller.refreshEvents

  .on "ready page:load", ->
    jQuery("#logo a").click => do controller.refreshEvents

  .on "ready page:load", ->
    notice.showAlert window.messageForRender if window.messageForRender

    jQuery("#events").bind "DOMSubtreeModified", resizeElements
    jQuery(window).resize resizeElements
    jQuery("#show_all_events, #show_my_events").click resizeElements

  .on "ready page:load", ->
    jQuery("#new_event_date").on "keyup", (e) ->
      $this = jQuery(this)
      val = do $this.val
      if ((e.keyCode > 47 && e.keyCode < 58) || e.keyCode == 8) && val.length < 11
        $this.val "#{val}." if e.keyCode != 8 && (val.length == 2 || val.length == 5)
      else
        $this.val val.slice(0, -1)

  .on "ready page:load", ->
    jQuery("#new_event_time").on "keyup", (e) ->
      $this = jQuery(this)
      val = do $this.val
      if ((e.keyCode > 47 && e.keyCode < 58) || e.keyCode == 8) && val.length < 6
          $this.val "#{val}:" if e.keyCode != 8 && val.length == 2
      else
        $this.val val.slice(0, -1)

  .on "ready page:load", ->
    do jQuery("#overlayOpacity").hide
    do jQuery("#formForCreateEventOverlay").hide
    do jQuery("#currentUserInformationOverlay").hide

  .on "ready page:load", => do eventsController.init
  .on "ready page:load", => do createEventDialog.init

resizeElements = ->
  windowWidth = do jQuery(jQuery(window)).width
  if jQuery("body").height() < jQuery(window).height()
    jQuery("#footer").css position: "absolute", bottom: "0px"
  else
    jQuery("#footer").css position: "static"
  if windowWidth < 800
    if windowWidth <= 448
      windowWidth = 448
    jQuery(".content").width windowWidth - 330
    if windowWidth < 708 && windowWidth > 464
      jQuery("#search_key").width windowWidth - 128
    else
      jQuery("#search_key").width 320