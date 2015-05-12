_                 = require 'underscore-plus'
path              = require 'path'
SublimeTabBarView = require './sublime-tab-bar-view'

module.exports =
  configDefaults:
    # tabs
    showIcons: true

    # tree view
    hideVcsIgnoredFiles: false
    hideIgnoredNames: false
    showOnRightSide: false
    sortFoldersBeforeFiles: true
    
  treeView: null

  activate: (@state) ->
    @forceSettings()
    @disableStockPackages()

    # tabs
    @paneSubscription = atom.workspaceView.eachPaneView (paneView) =>
      tabBarView = new SublimeTabBarView(paneView)
      @tabBarViews ?= []
      @tabBarViews.push(tabBarView)
      onPaneViewRemoved = (event, removedPaneView) =>
        return unless paneView is removedPaneView
        _.remove(@tabBarViews, tabBarView)
        atom.workspaceView.off('pane:removed', onPaneViewRemoved)
      atom.workspaceView.on('pane:removed', onPaneViewRemoved)
      tabBarView

    # tree view
    @state.attached ?= true if @shouldAttach()
    @createView() if @state.attached
    atom.workspaceView.command 'tree-view:show', => @createView().show()
    atom.workspaceView.command 'tree-view:toggle', => @createView().toggle()
    atom.workspaceView.command 'tree-view:toggle-focus', => @createView().toggleFocus()
    atom.workspaceView.command 'tree-view:reveal-active-file', => @createView().revealActiveFile()
    atom.workspaceView.command 'tree-view:toggle-side', => @createView().toggleSide()
    atom.workspaceView.command 'tree-view:add-file', => @createView().add(true)
    atom.workspaceView.command 'tree-view:add-folder', => @createView().add(false)
    atom.workspaceView.command 'tree-view:duplicate', => @createView().copySelectedEntry()
    atom.workspaceView.command 'tree-view:remove', => @createView().removeSelectedEntries()

  serialize: ->
    if @treeView?
      @treeView.serialize()
    else
      @state

  deactivate: ->
    # tree view
    @treeView?.deactivate()
    @treeView = null

    # tabs
    @paneSubscription?.off()
    tabBarView.remove() for tabBarView in @tabBarViews ? []

  # tree view
  createView: ->
    unless @treeView?
      SublimeTreeView = require './sublime-tree-view'
      @treeView = new SublimeTreeView(@state)
    @treeView

  shouldAttach: ->
    if atom.workspace.getActivePaneItem()
      false
    else if path.basename(atom.project.getPath()) is '.git'
      # Only attach when the project path matches the path to open signifying
      # the .git folder was opened explicitly and not by using Atom as the Git
      # editor.
      atom.project.getPath() is atom.getLoadSettings().pathToOpen
    else
      true

  forceSettings: ->
    @forceSettingKey('tabs','showIcons')
    atom.config.observe 'sublime-tabs.' + 'showIcons', =>
      @forceSettingKey('tabs','showIcons')

    @forceSettingKey('tree-view','hideVcsIgnoredFiles')
    atom.config.observe 'sublime-tabs.' + 'hideVcsIgnoredFiles', =>
      @forceSettingKey('tree-view','hideVcsIgnoredFiles')

    @forceSettingKey('tree-view','hideIgnoredNames')
    atom.config.observe 'sublime-tabs.' + 'hideIgnoredNames', =>
      @forceSettingKey('tree-view','hideIgnoredNames')

    @forceSettingKey('tree-view','showOnRightSide')
    atom.config.observe 'sublime-tabs.' + 'showOnRightSide', =>
      @forceSettingKey('tree-view','showOnRightSide')

    @forceSettingKey('tree-view','sortFoldersBeforeFiles')
    atom.config.observe 'sublime-tabs.' + 'sortFoldersBeforeFiles', =>
      @forceSettingKey('tree-view','sortFoldersBeforeFiles')

  forceSettingKey: (masterKey, key) ->
    value = atom.config.get 'sublime-tabs.' + "#{key}"
    value ?= atom.config.getDefault 'sublime-tabs.' + "#{key}"
    atom.config.set(masterKey + '.' + key, atom.config.get('sublime-tabs.' + "#{key}"))

  disableStockPackages: ->
    if atom.packages.isPackageLoaded('tabs')
        atom.packages.disablePackage('tabs')
        atom.packages.deactivatePackage('tabs')
        setTimeout ->
          atom.packages.deactivatePackage('tabs')
        , 2000

    if atom.packages.isPackageLoaded('tree-view')
        atom.packages.disablePackage('tree-view')
        atom.packages.deactivatePackage('tree-view')
        setTimeout ->
          atom.packages.deactivatePackage('tree-view')
        , 2000
