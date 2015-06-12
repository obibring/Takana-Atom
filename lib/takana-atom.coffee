{CompositeDisposable} = require 'atom'
path = require 'path'
nssocket = require 'nssocket'
{debounce} = require 'underscore'

SUPPORTED_FILE_TYPES = [
  '.sass'
  '.scss'
  '.less'
  '.css'
]

isStylesheetFile = (filePath) ->
  path.extname(filePath) in SUPPORTED_FILE_TYPES

CONSOLE_PREFIX = "TAKANA-ATOM:"
log = (message, force = no) ->
  if atom.config.get('takana-atom.debug') or force
    console.log "#{CONSOLE_PREFIX} #{message}"

error = (message) ->
  console.error "#{CONSOLE_PREFIX} #{message}"

warn = (message) ->
  console.warn "#{CONSOLE_PREFIX} #{message}"

now = ->
  new Date().getTime()

getPort = ->
  atom.config.get 'takana-atom.takanaServerPort'

TakanaAtom =
  subscriptions: null
  socket: null
  delay: 0.035 * 1000 # milliseconds

  config:
    takanaServerPort:
      title: 'Takana Server Port'
      description: 'The port your takana server is running on.'
      type: 'integer'
      default: 48627
      minimum: 1
    debug:
      title: 'Debug Mode'
      description: 'Whether to print debugging statements to the console.'
      type: 'boolean'
      default: no

  reconnect: ->
    warn "Re-connecting to Takana Server. You must refresh browser for live updates to continue."
    TakanaAtom.start()

  stop: ->
    warn "Killing connection to Takana Server."
    TakanaAtom.deactivate()

  start: ->
    if TakanaAtom.socket
      TakanaAtom.deactivate()

    #@takanaAtomView = new TakanaAtomView(state.takanaAtomViewState)
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    TakanaAtom.subscriptions = new CompositeDisposable()

    TakanaAtom.socket = socket = nssocket.NsSocket()

    reload = (editor) ->
      ->
        filepath = editor.getPath()
        log "publishing editor:reset message for #{filepath}"
        socket.send ['editor', 'reset'],
          path: filepath
          created_at: now()

    update = (editor) ->
      ->
        filepath = editor.getPath()
        log "publishing editor:update message for #{filepath}"
        socket.send ['editor', 'update'],
          path: filepath
          buffer: editor.getText()
          created_at: now()

    socket.connect getPort(), =>
      log "Connected to Takana Server on port #{getPort()}"
      atom.workspace.observeTextEditors (editor) ->
        if isStylesheetFile(editor.getPath())
          log "Observing updates for file: #{editor.getPath()}"
          onReload = reload editor
          TakanaAtom.subscriptions.add editor.onDidChange(debounce update(editor), @delay)
          TakanaAtom.subscriptions.add editor.onDidSave(onReload)
          TakanaAtom.subscriptions.add editor.onDidDestroy(onReload)

      socket.on 'close', ->
        warn """Lost connection to the Takana server.
          Check if the server was shut down. Once restarted you can reconnect
          using Packages > Takana-Atom > Reconnect To Takana Server."""
        TakanaAtom.subscriptions?.dispose()
        TakanaAtom.socket = null

    socket.on 'error', (e) ->
      if e?.code is "ECONNREFUSED"
        error """Unable to connect to Takana Server. Verify that it is running
        on port #{getPort()} and try again. You can try re-connecting using
        Packages > Takana-Atom > Reconnect To Takana Server."""

  activate: (state) ->
    atom.commands.add 'atom-workspace', 'takana-atom:reconnect': TakanaAtom.reconnect
    atom.commands.add 'atom-workspace', 'takana-atom:stop': TakanaAtom.stop
    TakanaAtom.start()

  deactivate: ->
    TakanaAtom.socket?.end()
    TakanaAtom.subscriptions?.dispose()
    TakanaAtom.socket = null
    TakanaAtom.subscriptions = null

module.exports = TakanaAtom
