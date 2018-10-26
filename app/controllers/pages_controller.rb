class PagesController < ApplicationController
  before_filter :authenticate_user!
  
  def import
    @import = current_user.import
  end

  def subscription
    puts Colorize.magenta(params)
    @subscriptions = Subscription.order('created_at DESC').paginate(:page => 1)
    @successful_subscriptions = Subscription.where("fail_count = 0").order('created_at DESC').paginate(:page => 1)
    @failed_subscriptions = Subscription.where("fail_count > 0").order('created_at DESC').paginate(:page => 1)

    puts @subscriptions.length
    puts Subscription.per_page

    if Subscription.count > @subscriptions.length
      @load_more = true
    else
      @load_more = false
    end

    if @successful_subscriptions.count > @successful_subscriptions.length
      @successful_load_more = true
    else
      @successful_load_more = false
    end

    if @failed_subscriptions.count > @failed_subscriptions.length
      @failed_load_more = true
    else
      @failed_load_more = false
    end
  end

  def subscription_page
    puts Colorize.magenta(params)
    if params["email"] == 'hide-no-email'
      @subscriptions = Subscription.where("lower(full_name) like ? AND (email IS NOT NULL AND trim(email) != '')", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      @successful_subscriptions = Subscription.where("lower(full_name) like ? AND (email IS NOT NULL AND trim(email) != '') AND fail_count = 0", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      @failed_subscriptions = Subscription.where("lower(full_name) like ? AND (email IS NOT NULL AND trim(email) != '') AND fail_count > 0", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      puts Colorize.green('hide-no-email')
    elsif params["email"] == 'hide-email'
      @subscriptions = Subscription.where("lower(full_name) like ? AND (email IS NULL OR trim(email) = '')", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      @successful_subscriptions = Subscription.where("lower(full_name) like ? AND (email IS NULL OR trim(email) = '') AND fail_count = 0", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      @failed_subscriptions = Subscription.where("lower(full_name) like ? AND (email IS NULL OR trim(email) = '') AND fail_count > 0", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      puts Colorize.green('hide-email')
    else
      @subscriptions = Subscription.where("lower(full_name) like ?", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      @successful_subscriptions = Subscription.where("lower(full_name) like ? AND fail_count = 0", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      @failed_subscriptions = Subscription.where("lower(full_name) like ? AND fail_count > 0", "%#{params["search"]&.downcase}%").order('created_at DESC').paginate(:page => params["page"])
      puts Colorize.green('nothing about email')
    end

    html_string = ''
    successful_html_string = ''
    failed_html_string = ''

    for subscription in @subscriptions
      html_string << render_to_string(partial: '/partials/subscription_row', locals: {subscription: subscription})
    end

    for subscription in @successful_subscriptions
      successful_html_string << render_to_string(partial: '/partials/subscription_row', locals: {subscription: subscription})
    end

    for subscription in @failed_subscriptions
      failed_html_string << render_to_string(partial: '/partials/subscription_row', locals: {subscription: subscription})
    end

    puts @subscriptions.length * params["page"].to_i

    if @subscriptions.count > Subscription.per_page * params["page"].to_i
      @load_more = true
    else
      @load_more = false
    end

    if @successful_subscriptions.count > Subscription.per_page * params["page"].to_i
      @successful_load_more = true
    else
      @successful_load_more = false
    end

    if @failed_subscriptions.count > Subscription.per_page * params["page"].to_i
      @failed_load_more = true
    else
      @failed_load_more = false
    end

    render json: {
      html: html_string,
      successful_html: successful_html_string,
      failed_html: failed_html_string,
      load_more: @load_more,
      successful_load_more: @successful_load_more,
      failed_load_more: @failed_load_more
    }
  end

  def log
    @events = Event.all.reverse
  end

  def users
    @users = User.all
  end

end
