# == Schema Information
#
# Table name: modifiers
#
#  id         :integer          not null, primary key
#  key        :string
#  value      :string
#  active     :boolean
#  recent     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

$MODIFIERS_RELOADED = false

require 'agis'

class Modifier < ActiveRecord::Base
  include Agis
  
  def arenew_modifier(k, v)
    old = Modifier.find_by(key: k, recent: true)
    if old and old.value == v and old.active == (v != nil)
      return true
    elsif old
      old.recent = false
      old.save!
    end
    Modifier.create(key: k, value: (v or ""), active: (v != nil), recent: true)
  end
  
  def agis_id
    "1"
  end
  
  def self.renew_modifier(k, v)
    Modifier.new.acall($redis, :arenew_modifier, k, v)
  end
  
  # Update all modifiers in this server instance
  def self.update_modifiers
    # puts $GAMERIST_MODIFIERS
    if !$MODIFIERS_RELOADED # we have the most recent data
      all_modifiers = Hash.new
      Modifier.where(recent: true).each do |mod|
        all_modifiers[mod.key] = mod.value if mod.active
      end
      $GAMERIST_MODIFIERS.each do |k, v|
        if(all_modifiers[k] != v.to_s)
          Modifier.renew_modifier(k, v)
        end
        $redis.hset("gamerist_modifiers", k, v)
      end
      $MODIFIERS_RELOADED = true
    # else # we do not have the most recent data
    # everything will come from redis anyway
    end
  end
  
  def self.get(k)
    if Gamerist.rake?
      return $GAMERIST_MODIFIERS[k]
    else
      x = $redis.hget("gamerist_modifiers", k)
      return (x or $GAMERIST_MODIFIERS[k])
    end
  end
  
  after_initialize do
    agis_defm2(:arenew_modifier)
  end
end

