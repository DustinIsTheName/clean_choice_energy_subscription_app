class Webhooks

  def self.create_recharge
    url = URI("https://api.rechargeapps.com/webhooks")

    webhooks = recharge_http_request(url, nil, 'get')

    for hook in webhooks["webhooks"]

      if hook["topic"] == "customer/deactivated"

        url = URI("https://api.rechargeapps.com/webhooks/#{hook["id"]}")

        deleted_hook = recharge_http_request(url, "{\n\n}", 'delete')

        print Colorize.red('Deleted webhook: ')
        print Colorize.red("customer/deactivated ")
        puts Colorize.red(deleted_hook)

      end

    end

    url = URI("https://api.rechargeapps.com/webhooks")

    # if ENV["HEROKU_ENV"] == 'production'
    #   webhook_body = {"address": "https://cce-subscriptions.herokuapp.com/recharge-delete-subscription", "topic": "subscription/cancelled"}
    # else
    #   webhook_body = {"address": "https://7a95ed18.ngrok.io/recharge-delete-subscription", "topic": "subscription/cancelled"}
    # end

    # webhook = recharge_http_request(url, webhook_body, 'post')

    # print Colorize.green('Created webhook: ')
    # puts Colorize.green(webhook)

    if ENV["HEROKU_ENV"] == 'production'
      webhook_body = {"address": "https://cce-subscriptions.herokuapp.com/recharge-delete-customer", "topic": "customer/deactivated"}
    else
      webhook_body = {"address": "https://7a95ed18.ngrok.io/recharge-delete-customer", "topic": "customer/deactivated"}
    end

    webhook = recharge_http_request(url, webhook_body, 'post')

    print Colorize.green('Created webhook: ')
    puts Colorize.green(webhook)
  end

  def self.create_recharge_subscription
    url = URI("https://api.rechargeapps.com/webhooks")

    webhooks = recharge_http_request(url, nil, 'get')

    for hook in webhooks["webhooks"]

      if hook["topic"] == "subscription/created"

        url = URI("https://api.rechargeapps.com/webhooks/#{hook["id"]}")

        deleted_hook = recharge_http_request(url, "{\n\n}", 'delete')

        print Colorize.red('Deleted webhook: ')
        print Colorize.red("subscription/created ")
        puts Colorize.red(deleted_hook)

      end

    end

    url = URI("https://api.rechargeapps.com/webhooks")

    # if ENV["HEROKU_ENV"] == 'production'
    #   webhook_body = {"address": "https://cce-subscriptions.herokuapp.com/recharge-delete-subscription", "topic": "subscription/cancelled"}
    # else
    #   webhook_body = {"address": "https://7a95ed18.ngrok.io/recharge-delete-subscription", "topic": "subscription/cancelled"}
    # end

    # webhook = recharge_http_request(url, webhook_body, 'post')

    # print Colorize.green('Created webhook: ')
    # puts Colorize.green(webhook)

    if ENV["HEROKU_ENV"] == 'production'
      webhook_body = {"address": "https://cce-subscriptions.herokuapp.com/single-from-online-store", "topic": "subscription/created"}
    else
      webhook_body = {"address": "https://7a95ed18.ngrok.io/single-from-online-store", "topic": "subscription/created"}
    end

    webhook = recharge_http_request(url, webhook_body, 'post')

    print Colorize.green('Created webhook: ')
    puts Colorize.green(webhook)
  end

  def self.create_stripe

  end

  def self.create_both
    create_stripe
    create_recharge
  end

  private

    def self.recharge_http_request(url, body = nil, type = nil)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      if type == "delete"
        request = Net::HTTP::Delete.new(url)
      elsif type == "post"
        request = Net::HTTP::Post.new(url)
      elsif type == "put"
        request = Net::HTTP::Put.new(url)
      elsif type == "get"
        request = Net::HTTP::Get.new(url)
      else
        request = Net::HTTP::Get.new(url)
      end

      request["x-recharge-access-token"] = ENV['RECHARGE_API_KEY']
      request["content-type"] = 'application/json'

      if body
        request.body = body.to_json
      end

      response = http.request(request)

      puts Colorize.yellow(request.body)
      puts Colorize.yellow(response.code)

      JSON.parse response.read_body
    end

end