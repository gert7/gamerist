require("coffee-script")
require("./test_helper")
expect = require("chai").expect

describe "Yo", ->
  it "should blow up", ->
    expect("a").to.equal "a"

