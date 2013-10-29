class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  def self.attach_steam(access_token, signed_in_resource=nil)
    data = access_token['user_info']
    signed_in_resource['']
  end
  
end
