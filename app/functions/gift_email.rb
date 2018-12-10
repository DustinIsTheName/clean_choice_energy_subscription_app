class GiftEmail

  def self.order_created(line_item)
    puts "order_created"

    if line_item["properties"].select{|p| p["name"] == "RecipientEmail"}.size > 0
      GiftMailer.gift_email(line_item).deliver
    end
  end

end