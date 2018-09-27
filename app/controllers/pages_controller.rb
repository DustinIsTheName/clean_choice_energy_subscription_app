class PagesController < ApplicationController
  before_filter :authenticate_user!
  
  def import
    @import = Import.last
  end

  def subscription
  end

  def log
    @events = Event.all.reverse
  end

  def users
  end

end
