class ShopifyOrder

  def self.create(product, first_name, last_name)
    order = ShopifyAPI::Order.new

    order.line_items = [
      {
        variant_id: product.variants.first.id,
        quantity: 1
      }
    ]

    order.tags = [
      first_name,
      last_name
    ].join(', ')

    puts Colorize.orange(order.attributes)

    if order.save
      puts Colorize.green("order saved")
    else
      puts Colorize.red(order.errors.messages)
    end
  end

end