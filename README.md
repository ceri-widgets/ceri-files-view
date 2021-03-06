# ceri-files-view

A simple, themed files view

### [Demo](https://ceri-widgets.github.io/ceri-files-view)


# Install

```sh
npm install --save-dev ceri-files-view ceri-tooltip ceri-fab ceri-progress ceri-toaster ceri-icon
```
## Usage

```coffee
FilesView = require("ceri-files-view")
# load the theme (see below)
FilesView(require("ceri-files-view/materialize"))
filesView = document.create "ceri-files-view"
# add files to view:
# names need to be unique
filesView.files = [
  {
    name: "someFile1"
    size: 100000
    lastModified: 0
  }
]
# add actions
filesView.rename = (file) -> new Promise (resolve, reject) =>
  # somehow rename file server-side
  resolve() # on success
  reject() # on fail
filesView.upload = (file, setProgress) -> new Promise (resolve, reject) =>
  # file is html5 file object
  # https://developer.mozilla.org/de/docs/Web/API/File
  # upload to server
  setProgress(50) # to set progress bar to 50%
filesView.delete = (file) -> new Promise (resolve,reject) =>
  # somehow delete file server-side
filesView.download = (file) -> # somehow trigger file download
```


## Themes
#### Materialize
- setup [ceri-materialize](https://github.com/ceri-comps/ceri-materialize)
- setup webpack for [ceri-icon](https://github.com/ceri-comps/ceri-icon). Include the following icons:
[`ma-file_upload`,`ma-delete_forever`,`ma-mode_edit`]

- load theme file
```coffee
filesView = FilesView(require("ceri-files-view/materialize"))
```

For example see [`dev/materialize`](dev/materialize.coffee).

# Development
Clone repository.
```sh
npm install
npm run dev
```
Browse to `http://localhost:8080/`.
## Notable changes
#### 0.2.0
- use ceri-materialize@2
## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
