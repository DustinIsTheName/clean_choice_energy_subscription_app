class GiftEmail

  def self.order_created(line_item, buyer_email, first_name, last_name)
    puts "order_created"

    if line_item["properties"].select{|p| p["name"] == "RecipientEmail"}.size > 0 or line_item["title"].downcase.include? "earth day"

      if line_item["title"].downcase.include? "valentine"
        GiftMailer.valentine_gift_email(line_item).deliver
      elsif line_item["title"].downcase.include? "earth day"
        GiftMailer.earth_day_gift_email(line_item, buyer_email, first_name, last_name).deliver
      else
        GiftMailer.gift_email(line_item).deliver
      end
    end
  end

end