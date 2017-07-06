module.exports =
  module:
    rules: [{ 
        test: /ceri-icon(\/src)?\/icon/
        enforce: "post"
        loader: "ceri-icon"
        options:
          icons: [
              "ma-file_upload"
              "ma-delete_forever"
              "ma-mode_edit"
            ]
    }]
