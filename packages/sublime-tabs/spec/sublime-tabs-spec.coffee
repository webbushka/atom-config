{$, WorkspaceView, View}  = require 'atom'
_                         = require 'underscore-plus'
path                      = require 'path'
SublimeTabBarView         = require '../lib/sublime-tab-bar-view'
SublimeTabView            = require '../lib/sublime-tab-view'
SublimeTreeView           = require '../lib/sublime-tree-view'

describe 'SublimeTabs Initialization', ->
  beforeEach ->
    atom.workspaceView = new WorkspaceView

    waitsForPromise ->
      atom.workspace.open('sample.js')
    waitsForPromise ->
      atom.packages.activatePackage('tabs')
    waitsForPromise ->
      atom.packages.activatePackage('tree-view')
    waitsForPromise ->
      atom.packages.activatePackage('sublime-tabs')

  it 'should deactivate and disable the tabs and tree-view package', ->
    expect(atom.packages.isPackageActive('tabs')).toBe false
    expect(atom.packages.isPackageActive('tree-view')).toBe false
    expect(atom.packages.isPackageDisabled('tabs')).toBe true
    expect(atom.packages.isPackageDisabled('tree-view')).toBe true

describe 'Sublime Tabs Package', ->
  beforeEach ->
    atom.workspaceView = new WorkspaceView

    waitsForPromise ->
      atom.workspace.open('sample.js')

    waitsForPromise ->
      atom.packages.activatePackage('sublime-tabs')

describe 'SublimeTabBarView', ->
  [item1, item2, editor1, pane, tabBar] = []

  class TestView extends View
    @deserialize: ({title, longTitle, iconName}) -> new TestView(title, longTitle, iconName)
    @content: (title) -> @div title
    initialize: (@title, @longTitle, @iconName) ->
    getTitle: -> @title
    getLongTitle: -> @longTitle
    getIconName: -> @iconName
    serialize: -> { deserializer: 'TestView', @title, @longTitle, @iconName }

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.model
    atom.deserializers.add(TestView)
    item1 = new TestView('Item 1', undefined, 'squirrel')
    item2 = new TestView('Item 2')

    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      editor1 = atom.workspace.getActiveEditor()
      pane = atom.workspaceView.getActivePaneView()
      pane.addItem(item1, 0)
      pane.addItem(item2, 2)
      pane.activateItem(item2)
      tabBar = new SublimeTabBarView(pane)

  afterEach ->
    atom.deserializers.remove(TestView)

  describe 'Temporary Tabs', ->
    describe 'Opening a new tab', ->
      it 'adds a temp class when opening a file', ->
        editor2 = null

        waitsForPromise ->
          atom.project.open('sample.txt').then (o) -> editor2 = o

        runs ->
          pane.activateItem(editor2)
          expect(tabBar.tabForItem(editor2)).toHaveClass 'temp'

      describe 'when there is an temp tab already', ->
        it 'will replace an existing temporary tab', ->
          editor2 = null
          editor3 = null

          waitsForPromise ->
            atom.project.open('sample.txt').then (o) ->
              editor2 = o
              pane.activateItem(editor2)
              atom.project.open('sample2.txt').then (o) ->
                editor3 = o
                pane.activateItem(editor3)

          runs ->
            expect(editor2.isDestroyed()).toBe true
            expect(editor3.isDestroyed()).toBe false
            expect(tabBar.tabForItem(editor2)).not.toExist()
            expect(tabBar.tabForItem(editor3)).toHaveClass 'temp'

        it 'makes the tab permanent when dbl clicking the tab', ->
          editor2 = null

          waitsForPromise ->
            atom.project.open('sample.txt').then (o) -> editor2 = o

          runs ->
            pane.activateItem(editor2)
            tabBar.tabForItem(editor2).trigger 'dblclick'
            expect(tabBar.tabForItem(editor2)).not.toHaveClass 'temp'

      describe 'when opening views that do not contain an editor', ->
        editor2 = null
        settingsView = null

        beforeEach ->
          waitsForPromise ->
            atom.project.open('sample.txt').then (o) ->
              editor2 = o
              pane.activateItem(editor2)

          waitsForPromise ->
            atom.packages.activatePackage('settings-view').then ->
              atom.workspaceView.open('atom://config').then (o) ->
                settingsView = o
                pane.activateItem(settingsView)

        it 'creates a permanent tab', ->
          expect(tabBar.tabForItem(settingsView)).toExist()
          expect(tabBar.tabForItem(settingsView)).not.toHaveClass 'temp'

        it 'keeps an existing temp tab', ->
          expect(tabBar.tabForItem(editor2)).toExist()
          expect(tabBar.tabForItem(editor2)).toHaveClass 'temp'

      describe 'when opening an image', ->
        it 'should be temporary', ->
          imageView = null

          waitsForPromise ->
            atom.workspace.open('sample.png').then (o) ->
              imageView = o
              pane.activateItem(imageView)

          runs ->
            expect(tabBar.tabForItem(imageView)).toHaveClass 'temp'

    describe 'when saving a file', ->
      it 'makes the tab permanent', ->
        editor2 = null
        waitsForPromise ->
          atom.workspace.open('sample.txt').then (o) ->
            editor2 = o
            pane.activateItem(editor2)

        runs ->
          atom.workspaceView.trigger 'core:save'
          expect(tabBar.tabForItem(editor2)).not.toHaveClass 'temp'


describe "tree-view:expand-directory-or-preview-file", ->
  treeView = null

  beforeEach ->
    fixturesPath = atom.project.getPaths()[0]
    path1 = path.join(fixturesPath, "tree-view", "dir1")
    atom.project.setPaths([path1])

    workspaceElement = atom.views.getView(atom.workspace)

    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.model

    waitsForPromise ->
      atom.packages.activatePackage("sublime-tabs")

    runs ->
      atom.commands.dispatch(workspaceElement, 'tree-view:toggle')
      treeView = $(atom.workspace.getLeftPanels()[0].getItem()).view()

  describe "when a collapsed directory is selected", ->
    it "expands the directory", ->
      subdir1 = treeView.find('.directory:eq(1)')
      subdir1.click() # select and expand
      subdir1.click() # collapse
      expect(subdir1).not.toHaveClass 'expanded'

      atom.commands.dispatch(treeView.element, 'tree-view:expand-directory-or-preview-file')

      expect(subdir1).toHaveClass 'expanded'

  describe "when an expanded directory is selected", ->
    it "keeps the directory expanded", ->
      subdir1 = treeView.find('.directory:eq(1)')
      subdir1.click() # select and expand
      expect(subdir1).toHaveClass 'expanded'

      atom.commands.dispatch(treeView.element, 'tree-view:expand-directory-or-preview-file')

      expect(subdir1).toHaveClass 'expanded'

  describe "when a file is selected", ->
    it "opens selected entry without loosing focus", ->
      treeViewPackage = atom.packages.getActivePackage('sublime-tabs').mainModule.treeView
      treeView.find('.directory:eq(1)').click()
      atom.commands.dispatch(treeView.element, 'core:move-down')
      spyOn(treeViewPackage, 'openSelectedEntry').andCallThrough()

      atom.commands.dispatch(treeView.element, 'tree-view:expand-directory-or-preview-file')

      expect(treeViewPackage.openSelectedEntry).toHaveBeenCalledWith(false)
