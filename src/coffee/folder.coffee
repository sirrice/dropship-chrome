class FoldersView
  constructor: (@root) ->
    @$root = $ @root
    @$content = $ '#content', @$root
    @$folders_list = $ '#folders_list', @$root
    @$debug = $ '#debug', @$root
    chrome.extension.onMessage.addListener @onMessage
    @loadURL()
    @loadFolders()
    @

  loadURL: ->
    @getURL (url) => @$content.text url

  getURL: (cb) ->
    chrome.runtime.getBackgroundPage (eventPage) =>
      cb eventPage.controller.url



  loadFolders: =>
    chrome.runtime.getBackgroundPage (eventPage) =>
      c = eventPage.controller
      c.dropboxChrome.client (client) =>
        @loadDropboxFolder client, '/', 1, @$folders_list, ()->{}

  loadDropboxFolder: (client, dir, depth, parent, cb) =>
    client.stat dir, {readDir:true}, (err, stat, stats) =>
      divs = (@addFolder client, s, depth, parent for s in stats when s.isFolder)
      cb(divs)

  hasSubFolders: (client, dir, cb) =>
    client.stat dir, {readDir: true}, (err, stat, stats) =>
      console.log ['has subfolders', dir, stats, stats.length]
      cb((s for s in stats when s.isFolder).length > 0)


  addFolder: (client, stat, depth, parent) =>
    add = $('<button>+</button>')
      .addClass('add')
    fName = $('<span>'+stat.name+'</span>')
      .addClass('folderName')
      .css({'margin-left': depth+'ex'})
    div = $('<div></div>')
      .addClass('row')
      .appendTo(parent)
      .append(add).append(fName)
    childDiv = $('<div></div>')
      .appendTo(div)
    children = null
    isShowing = false

    @hasSubFolders client, stat.path, (bSubFolders) ->
      if bSubFolders
        console.log ['adding subfolder class', stat.path]
        fName.addClass 'hasSubFolder'

    add.click (ev) =>
      @getURL (url) =>
        if (url)
          target_dir = stat.path
          @debug 'downloading ' + url + ' to '+stat.path
          # call dropboxChrome API to download
        else
          @debug 'no url'


    fName.click (ev) =>

      if children == null
        console.log ['loading children:', stat.path]
        @loadDropboxFolder client, stat.path, depth+1, childDiv, (divs)->
          children = divs
          console.log ['loaded children', stat.path, children]
        isShowing = true
      else
        if isShowing
          childDiv.empty()
        else
          # corner case: user clicks quickly before loadDropboxFolder finishes
          childDiv.append c for c in children
        isShowing = !isShowing
      ev.stopPropagation()

    div

  debug: (msg) =>
    @$debug.text msg




$ ->
  window.folderview = new FoldersView document.body
