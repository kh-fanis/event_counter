class Event < ActiveRecord::Base
  belongs_to :user

  scope :to_hash, ->(collection) do
    collection.to_a.map(&:serializable_hash)
  end

  scope :search, ->(l = 8, o) do
    all.limit(l).offset(o)
  end

  # scope :to_user_side, ->(events) do
  def self.to_user_side events
    events = Event.to_hash events
    events.each do |e|
      time = e["being_at"]
      hour = time.hour; min = time.min
      hour = "0#{hour}" if hour / 10 < 1; min = "0#{min}" if min / 10 < 1
      e[:time] = "#{hour}:#{min}"
      e[:date] = "#{time.day}.#{time.month}.#{time.year}"
      e[:author] = Event.find(e["id"]).user.full_name
    end
  end
end
