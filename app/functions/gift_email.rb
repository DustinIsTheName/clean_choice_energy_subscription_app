class GiftEmail

  def self.order_created(line_item)
    puts "order_created"

    if line_item["properties"].select{|p| p["name"] == "RecipientEmail"}.size > 0

      if line_item["title"].downcase.include? "valentine"
        GiftMailer.valentine_gift_email(line_item).deliver
      else
        GiftMailer.gift_email(line_item).deliver
      end
    end
  end

end