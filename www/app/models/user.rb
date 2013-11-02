class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :steamid, inverse_of: :user

  def attach_steam(access_token)
    steamuid = access_token['uid']
    @steamid = self.create_steamid(steamid: steamuid)
  end
  
end
