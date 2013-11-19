Gamerist.Views.Rooms ||= {}

class Gamerist.Views.Rooms.RoomView extends Backbone.View
  template: JST["backbone/templates/rooms/room"]

  events:
    "click .destroy" : "destroy"

  tagName: "tr"

  destroy: () ->
    @model.destroy()
    this.remove()

    return false

  render: ->
    $(@el).html(@template(@model.toJSON() ))
    return this
