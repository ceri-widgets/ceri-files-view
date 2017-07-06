module.exports = (theme, text) ->
  unless window.customElements.get("ceri-files-view")
    unless window.customElements.get("ceri-icon")
      window.customElements.define "ceri-icon", require("ceri-icon")
    unless window.customElements.get("ceri-tooltip")
      window.customElements.define "ceri-tooltip", require("ceri-tooltip")
    ceri = require "ceri/lib/wrapper"
    comp = require "./files-view-component"
    comp.mixins.push theme
    if text
      comp.mixins.push data: -> text: text
    window.customElements.define "ceri-files-view", ceri(comp)

