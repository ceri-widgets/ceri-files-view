
module.exports =

  mixins: [
    require "ceri/lib/structure"
    require "ceri/lib/computed"
    require "ceri/lib/class"
    require "ceri/lib/events"
    require "ceri/lib/style"
    require "ceri/lib/#model"
    require "ceri/lib/#show"
    require "ceri/lib/c-for"
    require "ceri/lib/c-mount"
    require "ceri/lib/setAttribute"
    require "ceri/lib/props"
    require "ceri/lib/util"
    require "ceri/lib/sort"
  ]
  structure: template 1, """
    <table #ref=table :class=classes.table>
      <thead>
        <tr>
          <th @click=sortBy("name")>
            <span :text=text.name></span>
            <span :class=classes.triangle :text="sortFilesSymbol.name"></span>
          </th>
          <th @click=sortBy("lastModified")>
            <span :text=text.modified></span>
            <span :class=classes.triangle :text="sortFilesSymbol.lastModified"></span>
          </th>
          <th @click=sortBy("size")>
            <span :text=text.size></span>
            <span :class=classes.triangle :text="sortFilesSymbol.size"></span>
          </th>
        </tr>
      </thead>
      <tbody #ref=tbody>
        <c-for names="file,i" id=name iterate=sortedFiles tap=scopes template=_listTemplate />
      </tbody>
    </table>
    <c-fab style="display:flex; flex-direction: column-reverse; position: absolute; right: 24px; bottom: 24px" @mousedown.prevent=noop @click=onFab></c-fab>
  """
  fab:
    rename:
      if: -> @selectedLength == 1
      child: null
      onClick: "renameSelected"
    delete:
      if: -> @selectedLength > 0
      child: null
      onClick: "deleteSelected"
    upload:
      child: template 1, """<input type="file" style="position:absolute;top:0;left:0;bottom:0;right:0;opacity:0" @change="onUpload" multiple></input>"""
      onClick: null

  events:
    dragover:
      this:
        prevent: true
        cbs: (e) -> e.dataTransfer.dropEffect = "copy"
    drop:
      this:
        prevent: true
        cbs: (e) -> @handleFiles(e.dataTransfer.files)
    click:
      this:
        notPrevented: true
        cbs: (e) -> 
          unless e.onFab
            @selected = {}
  sort:
    files: ["name",1]
  computed:
    selectedLength:
      noWait: true
      get: -> Object.keys(@selected).length
    droptext:
      get: ->
        if @files.length == 0
          return @text.drop
        else
          return ""
      cbs: (text) -> @$setAttribute("droptext",text)

  data: ->
    _lastSelected: null
    _listTemplate: template 1, """
      <tr @mousedown.not-prevented=select :class.expr="@selected[@file.name]?'active':''" @click.not-prevented.prevent=noop #ref=row>
        <td class=filename style="position:relative" #ref=namecell>
          <span :text=file.name #show.expr="!@selected[@file.name]"></span>
          <input $value=file.name #show.expr="@selected[@file.name]" #ref=input
            $file=file
            @click.prevent=noop
            @keyup=keyupRename
            @focus=focusRename
            @blur=blurRename
          ></input>
        </td>
        <td class=modified :text.expr=@getDateString(@file)></td>
        <td class=size :text.expr=@getSizeString(@file)></td>
      </tr>
    """
    selected: {}
    files: []
    preprocess: {}
    display: {}
    text:
      name: "Name"
      modified: "Modified"
      size: "Size"
      upload: "Upload"
      delete: "Delete"
      rename: "Rename"
      drop: "Drop files here"
    icon:
      upload: null
      delete: null
      rename: null
    classes:
      mainButton: null
      button: null
      tooltip: null
      uploadButton: null
      deleteButton: null
      renameButton: null

  methods:
    noop: (e) ->
    onFab: (e) ->
      e.onFab = true
    renameSelected: -> @_lastSelected?.input.focus()
        
    focusRename: -> @input.setSelectionRange(0, @file.name.length)
    keyupRename: (e) ->
      return if e.type == "keyup" and e.keyCode != 13
      @input.blur()
    blurRename: (e) ->
      target = e.target
      file = target.file
      newName = target.value
      oldName = file.name
      if newName != oldName
        restore = -> target.value = file.name = oldName
        return restore() if @isExisting(newName)
        file.name = newName
        close = @$progress 
          el: (cell = target.parentElement)
          onTimeout: restore
          init: width: cell.parentElement.offsetWidth+"px"
          preserve: "width"
        @rename newName, file
        .then close
        .catch ->
          restore()
          close()

    deleteSelected: ->
      len = (selected = Object.keys(@selected)).length
      selected.forEach (name) =>
        scope = @selected[name]
        close = @$progress
          el: scope.namecell
          init: width: scope.row.offsetWidth+"px"
          preserve: "width"
        @delete (file = scope.file)
        .then =>
          close()
          index = @files.indexOf(file)
          if index > -1
            @files.splice index,1
            @$watch.notify "files"
          delete @selected[name]
          @$watch.notify "selected"
        .catch close

    handleFiles: (files) ->
      localFiles = []
      for file in files
        unless @isExisting(file.name)
          newFile = 
            name: file.name
            size: file.size
            lastModified: file.lastModified
            file: file
          @files.push newFile
          localFiles.push newFile
      @$watch.notify "files"
      for file in localFiles
        file.scope = @getScopeByFile(file)
      finished = 0
      localFiles.forEach (file) =>
        scope = file.scope
        close = @$progress
          el: scope.namecell
          init: width: scope.row.offsetWidth+"px"
          preserve: "width"
        @upload file.file, close
        .then close
        .catch =>
          close() 
          index = @files.indexOf(file)
          if index > -1
            @files.splice index,1
          @$watch.notify "files"
        
    
    onUpload: (e) -> @handleFiles(e.target?.files)
    fillZero: (str) ->
      str = String(str)
      if str.length > 1
        return str
      else
        return "0"+str
    getDateString: (file) ->
      date = new Date(file.lastModified)
      day = @fillZero(date.getDay())
      month = @fillZero(date.getMonth()+1)
      year = date.getFullYear()
      hour = @fillZero(date.getHours())
      minute = @fillZero(date.getMinutes())
      return "#{day}.#{month}.#{year} #{hour}:#{minute}"
    getSizeString: (file) ->
      thresh = 1024
      bytes = file.size
      if Math.abs(bytes) < thresh
          return bytes + ' B'
      units = ['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB'];
      u = -1
      loop
        bytes /= thresh
        ++u
        break unless Math.abs(bytes) >= thresh && u < units.length - 1
      return bytes.toFixed(1)+' '+units[u]
    select: (e) ->
      toggle = (scope, last) =>
        if last
          if @selected[scope.file.name]
            @selected = {}
            @_lastSelected = null 
          else
            tmp = {}
            tmp[scope.file.name] = scope
            @selected = tmp
            @_lastSelected = scope
        else 
          if @selected[scope.file.name]
            delete @selected[scope.file.name]
          else
            @selected[scope.file.name] = scope
          @$watch.notify "selected"
      if e and e.type == "mousedown"
        if e.shiftKey and @_lastSelected
          if @_lastSelected == @file
            return toggle(@,true)
          start = @getScopeIndexByFile(@_lastSelected.file)
          end = @getScopeIndexByFile(@file)
          if start > end
            tmp = @scopes.slice(end,start)
          else
            tmp = @scopes.slice(start+1,end+1)
          for file in tmp
            toggle(file,false)
          return e.preventDefault()
        else if e.ctrlKey
          toggle(@, false)
          return e.preventDefault()
      unless e.target.nodeName == "INPUT"
        toggle(@, true)

    getScopeByFile: (file) ->
      for scope,i in @scopes
        if scope.file == file
          return scope
      return null
    getScopeIndexByFile: (file) ->
      for scope,i in @scopes
        if scope.file == file
          return i
      return -1
    isExisting: (name) ->
      for scope,i in @scopes
        if scope.file.name == name
          return true
      return false
    sortBy: (field, e) ->
      @$sort.by field: field, target:"files", add:e.ctrlKey