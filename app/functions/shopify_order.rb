class ShopifyOrder

  def self.create(product, subscription)
    order = ShopifyAPI::Order.new

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
    puts Colorize.green("order saved")

    job_id = ShopifyOrder.delay({run_at: 1.month.from_now}).create(product, subscription).id

    subscription.job_id = job_id
    subscription.save
  end

end