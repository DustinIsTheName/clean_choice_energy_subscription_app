class ProcessMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)

  default to: 'dustin@wittycreative.com'
  # default to: 'travis@wittycreative.com'

  def subscription_canceled(subscription)

    @subscription = subscription
    @product = ShopifyAPI::Product.find(subscription.product)
    @shop = ShopifyAPI::Shop.current

    if @subscription.email
      mail(to: @subscription.email, from: 'cleanchoiceenergy@no-reply.com', subject: 'Subscription Canceled')
    end

  end

end