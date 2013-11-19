class Gamerist.Models.Room extends Backbone.Model
  paramRoot: 'room'

  defaults:
    owner: null
    game_id: null
    state: null
    server_id: null
    ruleset_id: null

class Gamerist.Collections.RoomsCollection extends Backbone.Collection
  model: Gamerist.Models.Room
  url: '/rooms'
