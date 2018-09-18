class Event < ApplicationRecord
  serialize :event_lines, Array
end
