class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  has_many :steamids

  def self.attach_steam(access_token, user=nil)
    data = access_token['user_info']
    Steamid.create(user_id: signed_in_resource.id, steamid: data)
  end
  
end
