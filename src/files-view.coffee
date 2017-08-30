module.exports = (theme, text) ->
  unless window.customElements.get("ceri-files-view")
    ceri = require "ceri/lib/wrapper"
    comp = require "./files-view-component"
    comp.mixins.push theme
    if text
      comp.mixins.push data: -> text: text
    window.customElements.define "ceri-files-view", ceri(comp)

