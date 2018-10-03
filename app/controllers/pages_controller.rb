class PagesController < ApplicationController
  before_filter :authenticate_user!
  
  def import
    @import = current_user.import
  end

  def subscription
    @subscriptions = Subscription.all
  end

  def log
    @events = Event.all.reverse
  end

  def users
  end

end
