class ShopifyOrder

  def self.create(product, subscription_id)
    order = ShopifyAPI::Order.new
    subscription = Subscription.find(subscription_id)

    order.line_items = [
      {
        variant_id: product.variants.first.id,
        quantity: 1
      }
    ]

    order.tags = [
      subscription.first_name,
      subscription.last_name
    ].join(', ')

    puts Colorize.orange(order.attributes)

    if order.save
      puts Colorize.green("order saved")
    else
      puts Colorize.red(order.errors.messages)
    end

    job_id = ShopifyOrder.delay({run_at: 1.month.from_now}).create(product, subscription_id).id

    subscription.job_id = job_id
    subscription.save
  end

end