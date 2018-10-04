class ProcessesController < ApplicationController

  def import
    Stripe.api_key = CURRENT_STRIPE_SECRET_KEY

    # puts Colorize.magenta(params)
    event_lines = [] # initialize event lines array to fill in during loop

    ################################################################################
    # Read and parse CSV, save import then loop through the CSV rows
    ################################################################################
    csv_text = File.read(params["CsvDoc"].path)
    csv = CSV.parse(csv_text, :headers => true)

    if current_user.import
      current_user.import.transactions.destroy_all
      current_user.import.destroy
    end

    import = Import.new
    import.transaction_count = csv.count
    import.user_id = current_user.id
    import.save

    csv.each do |row|
      row = row.to_hash
      subscription = Subscription.find_by({first_name: row["First Name"]&.strip, last_name: row["Last Name"]&.strip, cc_number: row["Credit Card #"].to_s.strip.slice(-4,4)})

      unless row["Subscription Product"].blank?
        begin
          product = ShopifyAPI::Product.find(row["Subscription Product"])
        rescue => e
          puts e
        end
      end
      transaction = InternalSubscription.create(row, import, subscription, product)
      event_lines << {
        successful: transaction.status,
        text: "##{transaction.id} - #{transaction.name} - #{transaction.email} - #{product&.title} - $#{product&.variants&.first&.price} - #{transaction.cc_number}"
      }
    end

    ################################################################################
    # Create and save an Event for the Logs
    ################################################################################
    event = Event.new
    event.name = "Import: Batch # #{import.id}"
    event.event_type = "import"
    event.event_lines = event_lines
    event.user_id = current_user.id

    event.save

    render json: import, :include => [:transactions]
  end

  def single
    Stripe.api_key = CURRENT_STRIPE_SECRET_KEY

    row = params["row"]

    if current_user.import
      current_user.import.transactions.destroy_all
      current_user.import.destroy
    end

    import = Import.new
    import.transaction_count = 1
    import.user_id = current_user.id
    import.save

    subscription = Subscription.find_by({first_name: row["First Name"]&.strip, last_name: row["Last Name"]&.strip, cc_number: row["Credit Card #"].to_s.strip.slice(-4,4)})

    unless row["Subscription Product"].blank?
      begin
        product = ShopifyAPI::Product.find(row["Subscription Product"])
      rescue => e
        error_codes << 'Product not found'
      end
    end

    transaction = InternalSubscription.create(row, import, subscription, product)
    event_lines = [{
      successful: transaction.status,
      text: "##{transaction.id} - #{transaction.name} - #{transaction.email} - #{product&.title} - $#{product&.variants&.first&.price} - #{transaction.cc_number}"
    }]

    ################################################################################
    # Create and save an Event for the Logs
    ################################################################################
    event = Event.new
    event.name = "Import: Batch # #{import.id}"
    event.event_type = "import"
    event.event_lines = event_lines
    event.user_id = current_user.id

    event.save

    render json: import, :include => [:transactions]
  end

  def edit
    subscription = Subscription.find(params["subscription_id"])

    event_lines = [{
      successful: true,
      text: "Subscription # #{subscription.id} was updated."
    }]

    if subscription.payment_service == "recharge"
      url = URI("https://api.rechargeapps.com/customers/#{subscription.external_customer_id}")
      new_customer_params = {
        first_name: params["first_name"],
        last_name: params["last_name"],
        email: params["email"]
      }
      recharge_customer = recharge_http_request(url, new_customer_params, 'put')
    elsif subscription.payment_service == "stripe"

      begin
        stripe_customer = Stripe::Customer.retrieve(subscription.external_customer_id)

        if stripe_customer
          stripe_customer.description = "Customer: #{params["first_name"]} #{params["last_name"]}"
          if params["email"].blank?
            stripe_customer.email = nil
          else
            stripe_customer.email = params["email"]
          end

          if stripe_customer.save
            puts Colorize.green('updated Stripe Customer')
          else
            puts Colorize.red('error updating Stripe Customer')
          end
        end

      rescue => e
        puts e
      end

    end

    unless subscription.first_name == params["first_name"]
      event_lines << {
        successful: true,
        text: "Updated first name to #{params["first_name"]}"
      }
    end
    unless subscription.last_name == params["last_name"]
      event_lines << {
        successful: true,
        text: "Updated last name to #{params["last_name"]}"
      }
    end
    unless subscription.email == params["email"]
      event_lines << {
        successful: true,
        text: "Updated email to #{params["email"]}"
      }
    end

    subscription.first_name = params["first_name"]
    subscription.last_name = params["last_name"]
    subscription.email = params["email"]

    if subscription.save
      puts Colorize.green('updated Internal Subscription')
    else
      puts Colorize.red('error updating Internal Subscription')
    end

    ################################################################################
    # Create and save an Event for the Logs
    ################################################################################
    if event_lines.length > 1
      event = Event.new
      event.name = "Update"
      event.event_type = "update"
      event.event_lines = event_lines
      event.user_id = current_user.id

      event.save
    end

    render json: params
  end

  def delete
    puts params

    subscription = Subscription.find(params[:subscription_id])

    if subscription.payment_service == "recharge"

      url = URI("https://api.rechargeapps.com/customers/#{subscription.external_customer_id}")
      sub_url = URI("https://api.rechargeapps.com/subscriptions/#{subscription.external_id}")

      recharge_customer = recharge_http_request(url)
      recharge_subscription = recharge_http_request(sub_url)

      puts Colorize.blue(subscription.external_customer_id)
      puts Colorize.orange(recharge_customer)
      puts Colorize.yellow(recharge_subscription)

      if recharge_customer["customer"] and recharge_subscription["subscription"]
        puts Colorize.yellow('in recharge_customer deletion')
        # stripe_customer = Stripe::Customer.retrieve(recharge_customer["stripe_customer_token"])

        # if stripe_customer 
        #   stripe_customer.delete
        # end

        puts recharge_http_request(sub_url, "{\n\n}", "delete")
        puts recharge_http_request(url, "{\n\n}", "delete")

      else
        puts Colorize.yellow('NOT!!!')
      end

    elsif subscription.payment_service == "stripe"

      begin
        stripe_customer = Stripe::Customer.retrieve(subscription.external_customer_id)
        stripe_subscription = Stripe::Subscription.retrieve(subscription.external_id)

        if stripe_subscription
          stripe_subscription.delete
        end

        if stripe_customer
          stripe_customer.delete
        end

      rescue => e
        puts e
      end

    end

    subscription.destroy

    ################################################################################
    # Create and save an Event for the Logs
    ################################################################################
    event = Event.new
    event.name = "Cancel"
    event.event_type = "cancel"
    event.event_lines = [{
        successful: true,
        text: "Subscription # #{subscription.id} was canceled."
      }]
    event.user_id = current_user.id

    event.save

    render json: {
      subscription: subscription,
      recharge_customer: recharge_customer,
      stripe_customer: stripe_customer,

    }
  end

  def download
    send_file 'public/csv_template.csv', type: 'text/csv', status: 202
  end

  private

    def recharge_http_request(url, body = nil, type = nil)
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