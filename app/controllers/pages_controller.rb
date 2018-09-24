class PagesController < ApplicationController
  before_filter :authenticate_user!
  
  def import
    @import = Import.last
  end

  def subscription
  end

  def log
  end

  def users
  end

end
