
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
    require "ceri/lib/@tap"
    require "ceri/lib/states"
  ]
  structure: template 1, """
    <table #ref=table>
      <thead>
        <tr>
          <th @click=sortBy("name") class=filename >
            <span :text=text.name></span>
            <span :class=classes.triangle :text="sortFilesSymbol.name"></span>
          </th>
          <th @click=sortBy("lastModified") class=modified >
            <span :text=text.modified></span>
            <span :class=classes.triangle :text="sortFilesSymbol.lastModified"></span>
          </th>
          <th @click=sortBy("size") class=size>
            <span :text=text.size></span>
            <span :class=classes.triangle :text="sortFilesSymbol.size"></span>
          </th>
        </tr>
      </thead>
      <tbody #ref=tbody>
        <c-for 
          names="file,i"
          id=name
          iterate=sortedFiles
          tap=scopes 
          computed=_listComputed
          >
          <template>
            <tr 
              :class.expr="@isSelected?'active':''" 
              @click.inside=select
              #ref=row
              >
              <@dblclick=leech(file) active.expr="@isSelected && !@isRenaming" />
              <@tap=leech(file) active.expr="@isSelected && !@isRenaming" not-prevented=true />
              <td 
                class=filename 
                style="position:relative" 
                #ref=namecell
                >
                
                <span :text=file.name #show.not="isRenaming">
                  <@click=rename-click(@) active="ui.canRename" />
                  <@tap=rename-click(@) active="ui.canRename" prevent=true />
                </span>
                <input $value=file.name #show="isRenaming" #ref=input
                  $file=file
                  @click.prevent
                  @keyup=keyupRename
                  @focus=focusRename
                  @blur=blurRename
                ></input>
              </td>
              <td class=modified :text.expr=@getDateString(@file)></td>
              <td class=size :text.expr=@getSizeString(@file)></td>
            </tr>
          </template>
        </c-for>
      </tbody>
    </table>
    <c-fab></c-fab>
  """
  computedClass:
    table: ->
      obj = {}
      obj[@classes.table] = true if @classes.table?
      obj[@ui._state+"State"] = true
      return obj

  states:
    ui:
      initial: ["select"]
      select: ["select","selectMultiple","rename","delete","download"]
      selectMultiple: ["select","selectMultiple","delete"]
      rename: 
        next: ["select"]
        can: -> @ui.select or @ui.delete?.length == 1
        cbs: "renameSelected"
      delete: ["select","deleteConfirm"]
      deleteConfirm: 
        next: []
        cbs: "deleteSelected"
      download: []
      upload: 
        next: ["select"]
        can: -> true
  fab:
    ui:
      rename: {}
      delete: {}
      deleteConfirm: {}
      upload:
        child: template 1, """<input type="file" style="position:absolute;top:0;left:0;bottom:0;right:0;opacity:0" @change="onUpload" multiple></input>"""

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
        self: true
        cbs: "ui('initial')"
          
  sort:
    files: ["name",1]
  computed:
    selected: -> @ui.select or @ui.selectMultiple or @ui.delete or @ui.rename or @ui.deleteSelected
    droptext:
      get: ->
        if @files.length == 0
          return @text.drop
        else
          return ""
      cbs: (text) -> @$setAttribute("droptext",text)

  data: ->
    _listComputed:
      isSelected: ->
        if a = @selected
          return ~a.indexOf(@)
        return false
      isRenaming: -> @ui.rename?[0] == @

    download: null
    files: []
    preprocess: {}
    display: {}
    text:
      name: "Name"
      modified: "Modified"
      size: "Size"
      upload: "Upload"
      delete: "Delete"
      deleteConfirm: "Confirm delete"
      rename: "Rename"
      failed: "failed"
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
    setSelect: (arr) ->
      arr = arr.reduce ((acc, val) -> acc.push(val) if val?; return acc), []
      type = switch arr.length
        when 0 then "initial"
        when 1 then "select"
        else "selectMultiple"
      @ui(type, arr)
    leech: (file,e) -> @download? file
    renameClick: (scope) -> @ui("rename",[scope])
    renameSelected: (scope) -> scope[0].input.focus() if scope
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
        @rename newName, oldName
        .then =>
          @ui "initial"
          close()
        .catch =>
          restore()
          close()
          @$toast text: @text.rename + " " + @text.failed + ": " + oldName
      else
        @ui "initial"

    deleteSelected: (scope) ->
      if scope
        Promise.all(scope.map (scope) =>
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
            return null
          .catch =>
            close()
            @$toast text: @text.delete + " " + @text.failed + ": " + name
            return scope
        ).then @setSelect.bind(@)

    handleFiles: (files) ->
      @ui("initial")
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
      Promise.all localFiles.map (file) =>
        scope = file.scope
        close = @$progress
          el: scope.namecell
          init: width: scope.row.offsetWidth+"px"
          preserve: "width"
        return @upload file.file, close
          .then => 
            close()
            return file.scope
          .catch =>
            close() 
            index = @files.indexOf(file)
            if index > -1
              @files.splice index,1
            @$watch.notify "files"
            @$toast text: @text.upload + " " + @text.failed + ": " + file.name
            return null
      .then @setSelect.bind(@)
    
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
      if @ui.canSelectMultiple
        if e.shiftKey
          arr = @selected
          if arr[0]
            start = @scopes.indexOf(arr[0])
            end = @scopes.indexOf(@)
            if start > end
              tmp = @scopes.slice(end,start+1).reverse()
            else
              tmp = @scopes.slice(start,end+1)
            return @setSelect tmp
        if e.ctrlKey
          arr = @ui.select or @ui.selectMultiple
          if ~(i = arr.indexOf(@))
            arr.splice(i,1)
          else
            arr.push @
          return @setSelect arr
      return @setSelect [@] if @ui.canSelect and (not @ui.rename or @ui.rename[0] != @)
        
    getScopeByFile: (file) ->
      for scope,i in @scopes
        if scope.file == file
          return scope
      return null
    isExisting: (name) ->
      for scope,i in @scopes
        if scope.file.name == name
          return true
      return false
    sortBy: (field, e) ->
      @$sort.by field: field, target:"files", add:e.ctrlKey