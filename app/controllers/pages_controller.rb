class PagesController < ApplicationController
  before_filter :authenticate_user!
  
  def import
    @import = current_user.import
  end

  def subscription
    puts Colorize.magenta(params)
    @subscriptions = Subscription.order('created_at DESC').paginate(:page => 1)

    puts @subscriptions.length
    puts Subscription.per_page

    if Subscription.count > @subscriptions.length
      @load_more = true
    else
      @load_more = false
    end
  end

  def subscription_page
    puts Colorize.magenta(params)
    @subscriptions = Subscription.where("full_name like ?", "%#{params["search"]}%").order('created_at DESC').paginate(:page => params["page"])

    html_string = ''

    for subscription in @subscriptions
      html_string << render_to_string(partial: '/partials/subscription_row', locals: {subscription: subscription})
    end

    puts @subscriptions.length * params["page"].to_i

    if @subscriptions.count > Subscription.per_page * params["page"].to_i
      @load_more = true
    else
      @load_more = false
    end

    render json: {html: html_string, load_more: @load_more}
  end

  def log
    @events = Event.all.reverse
  end

  def users
  end

end
