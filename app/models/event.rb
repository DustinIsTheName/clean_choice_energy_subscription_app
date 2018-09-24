class Event < ApplicationRecord
  serialize :event_lines, Array

  belongs_to :user
end
