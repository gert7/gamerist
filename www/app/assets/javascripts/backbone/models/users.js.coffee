class Gamerist.Models.Users extends Backbone.Model
  paramRoot: 'user'

  defaults:

class Gamerist.Collections.UsersCollection extends Backbone.Collection
  model: Gamerist.Models.Users
  url: '/users'
