require "./materialize.config.scss"
require("../src/files-view.coffee")(require("../src/materialize.coffee"))

createView = require "ceri-dev-server/lib/createView"
module.exports = createView

  structure: template 1, """
    <ceri-files-view class="fullsize" #ref=fv></ceri-files-view>
  """
  connectedCallback: ->
    @fv.files = [
      {
        name: "someFile1"
        size: 100000
        lastModified: 0
      },
      {
        name: "someFile2"
        size: 1000000
        lastModified: 100000000000
      },
      {
        name: "someFile3"
        size: 10000000
        lastModified: 1000000000000
      }
    ]
    @fv.rename = @fv.upload = @fv.delete = -> new Promise (resolve,reject) -> setTimeout reject, 2000
  tests: (el) ->
    describe "files-view", ->
      after ->
        el.remove()
      it "should work", ->
