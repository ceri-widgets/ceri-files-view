module.exports =
  mixins: [
    require("ceri-fab")(require("ceri-fab/materialize"))
    require("ceri-progress/mixin")(require("ceri-progress/materialize"))
    require("ceri-toaster/mixin")(require("ceri-toaster/materialize"))
  ]
  data: ->
    icon:
      upload: "ma-file_upload"
      delete: "ma-delete_forever"
      deleteConfirm: "ma-delete_forever"
      rename: "ma-mode_edit"
    classes:
      deleteConfirmButton: "red"
      table: "highlight"
      triangle: "triangle"