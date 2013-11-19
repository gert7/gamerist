Gamerist.Views.Rooms ||= {}

class Gamerist.Views.Rooms.ShowView extends Backbone.View
  template: JST["backbone/templates/rooms/show"]

  render: ->
    $(@el).html(@template(@model.toJSON() ))
    return this
