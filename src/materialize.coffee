module.exports =
  mixins: [
    require("ceri-fab")(require("ceri-fab/materialize"))
    require("ceri-progress/mixin")(require("ceri-progress/materialize"))
  ]
  data: ->
    icon:
      upload: "ma-file_upload"
      delete: "ma-delete_forever"
      rename: "ma-mode_edit"
    classes:
      deleteButton: "red"
      table: "highlight"
      triangle: "triangle"