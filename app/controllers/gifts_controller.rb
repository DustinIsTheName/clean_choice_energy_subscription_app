class GiftsController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def gift_email

    puts Colorize.magenta(params)

    for item in params["line_items"]
      GiftEmail.delay.order_created(item)
    end

    head :ok
  end

  def view_pdf
    @line_item = {"id"=>1430701309994, "variant_id"=>13676039766058, "title"=>"100% Clean Energy Plan (Ships every 30 Days)", "quantity"=>1, "price"=>"19.00", "sku"=>"", "variant_title"=>"2 Acres (offsets 2 tons of CO2)", "vendor"=>"CleanChoice Energy", "fulfillment_service"=>"manual", "product_id"=>1602141356074, "requires_shipping"=>true, "taxable"=>false, "gift_card"=>false, "name"=>"100% Clean Energy Plan (Ships every 30 Days)", "variant_inventory_management"=>nil, "properties"=>[{"name"=>"RecipientFirstName", "value"=>"Matt"}, {"name"=>"RecipientLastName", "value"=>"Patt"}, {"name"=>"RecipientEmail", "value"=>"dustin@wittycreative.com"}, {"name"=>"Gifter Name", "value"=>"Kurthnaga"}], "product_exists"=>true, "fulfillable_quantity"=>0, "grams"=>4535924, "total_discount"=>"0.00", "fulfillment_status"=>"fulfilled", "discount_allocations"=>[], "tax_lines"=>[]}
  end

end