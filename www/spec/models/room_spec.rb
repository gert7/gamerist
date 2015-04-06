# == Schema Information
#
# Table name: rooms
#
#  id         :integer          not null, primary key
#  state      :integer
#  created_at :datetime
#  updated_at :datetime
#  rules      :text
#

require 'spec_helper'

include Warden::Test::Helpers
Warden.test_mode!

describe 'Room creation' do
  before(:each) do
  end
end

