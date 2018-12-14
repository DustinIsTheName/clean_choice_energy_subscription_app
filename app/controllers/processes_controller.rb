class ProcessesController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:recharge_delete_subscription, :recharge_delete_customer, :stripe_delete, :stripe_failed, :single_from_online_store]

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
        text: "##{transaction.subscription_id} - #{transaction.name} - #{transaction.email} - #{product&.title} - $#{product&.variants&.first&.price} - #{transaction.cc_number}"
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
      text: "##{transaction.subscription_id} - #{transaction.name} - #{transaction.email} - #{product&.title} - $#{product&.variants&.first&.price} - #{transaction.cc_number}"
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

  def single_from_online_store
    puts Colorize.magenta(params)

    Stripe.api_key = CURRENT_STRIPE_SECRET_KEY

    row = {}

    url = URI("https://api.rechargeapps.com/customers/#{params["subscription"]["customer_id"]}")

    customer = recharge_http_request url

    import = Import.new
    import.transaction_count = 1
    import.save

    subscription = Subscription.find_by({first_name: customer["customer"]["first_name"], last_name: customer["customer"]["last_name"], cc_number: "Shopify Order"})

    begin
      product = ShopifyAPI::Product.find(params["subscription"]["shopify_product_id"])
    rescue => e
      error_codes << 'Product not found'
    end

    unless subscription
        
      subscription = Subscription.new 

      ################################################################################
      # ReCharge
      ################################################################################
      subscription.first_name = customer["customer"]["first_name"]
      subscription.last_name = customer["customer"]["last_name"]
      subscription.email = customer["customer"]["email"]
      subscription.address = {
        street_address: customer["customer"]["billing_address1"],
        street_address_2: customer["customer"]["billing_address2"],
        city: customer["customer"]["billing_city"],
        state: customer["customer"]["billing_province"],
        zip: customer["customer"]["billing_zip"]
      }
      subscription.cc_number = "Shopify Order"
      subscription.external_id = params["subscription"]["id"]
      subscription.product = params["subscription"]["shopify_product_id"]
      subscription.payment_service = 'recharge'
      subscription.external_customer_id = customer["customer"]["id"]
      subscription.amount = params["subscription"]["price"]
      subscription.full_name = "#{customer["customer"]["first_name"]} #{customer["customer"]["last_name"]}"
      subscription.stripe_customer_id = nil
      subscription.fail_count = 0

      subscription.save

      event_lines = [{
        successful: true,
        text: "##{subscription.id} - #{subscription.full_name} - #{subscription.email} - #{product&.title} - $#{product&.variants&.first&.price} - Order from Store"
      }]

      ################################################################################
      # Create and save an Event for the Logs
      ################################################################################
      event = Event.new
      event.name = "Import: Batch # #{import.id}"
      event.event_type = "import"
      event.event_lines = event_lines

      event.save
    end

    head :ok
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
    subscription.full_name = "#{params["first_name"]} #{params["last_name"]}"
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

  def retry
    puts Colorize.magenta(params)

    Stripe.api_key = CURRENT_STRIPE_SECRET_KEY

    import = Import.find(params[:import_id])
    old_transaction = Transaction.find(params[:transaction_id])

    row = {}

    row["First Name"] = old_transaction.first_name
    row["Last Name"] = old_transaction.last_name
    row["Email"] = old_transaction.email
    row["Street Address"] = old_transaction.street_address
    row["Street Address 2"] = old_transaction.street_address_2
    row["City"] = old_transaction.city
    row["State"] = old_transaction.state
    row["Zip"] = old_transaction.zip
    row["Credit Card #"] = params["card_number"]
    row["Credit Card Expiration (MM/YY)"] = params["card_expiration"]
    row["Subscription Product"] = old_transaction.product
    row["stripe_token"] = old_transaction.stripe_token

    subscription = Subscription.find_by({first_name: row["First Name"]&.strip, last_name: row["Last Name"]&.strip, cc_number: row["Credit Card #"].to_s.strip.slice(-4,4)})

    unless row["Subscription Product"].blank?
      begin
        product = ShopifyAPI::Product.find(row["Subscription Product"])
      rescue => e
        error_codes << 'Product not found'
      end
    end

    transaction = InternalSubscription.create(row, import, subscription, product)

    old_transaction.destroy

    event_lines = [{
      successful: transaction.status,
      text: "##{transaction.subscription_id} - #{transaction.name} - #{transaction.email} - #{product&.title} - $#{product&.variants&.first&.price} - #{transaction.cc_number}"
    }]

    ################################################################################
    # Create and save an Event for the Logs
    ################################################################################
    event = Event.new
    event.name = "Retry: Batch # #{import.id}"
    event.event_type = "retry"
    event.event_lines = event_lines
    event.user_id = current_user.id

    event.save

    render json: {
      transaction: transaction
    }
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

        ProcessMailer.subscription_canceled(subscription).deliver

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

  def add_user

    puts Colorize.cyan(params)

    if params["user"]["password"] == params["user"]["confirm_password"]
      user = User.create({
        first_name: params["user"]["first_name"],
        last_name: params["user"]["last_name"],
        email: params["user"]["email"],
        access: params["user"]["access"],
        password: params["user"]["password"]
      })

      if user.save
        puts Colorize.green('User saved')
        render json: user
      else
        puts Colorize.red('User error')
        puts Colorize.red(user.errors.messages)
        render json: {errors: user.errors}
      end
    else
      render json: {errors: {passwords: ["don't match"]}}
    end

  end

  def edit_user
    puts Colorize.cyan(params)

    user = User.find(params[:user_id])
    user.first_name = params["first_name"]
    user.last_name = params["last_name"]
    user.email = params["email"]
    user.access = params["access"]

    if user.save
      puts Colorize.green('updated User')
    else
      puts Colorize.red('error updating User')
    end

    render json: user
  end

  def delete_user
    puts Colorize.cyan(params)

    user = User.find(params[:user_id])
    user.destroy

    render json: user
  end

  def recharge_delete_subscription
    puts Colorize.cyan(params)

    subscription = Subscription.find_by_external_id(params["subscription"]["id"])

    if subscription

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

      subscription.destroy
    end


  end

  def recharge_delete_customer
    puts Colorize.magenta(params)

    subscription = Subscription.find_by_external_customer_id(params["customer"]["id"])

    if subscription
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
    end
  end

  def stripe_delete
    puts Colorize.green(params)

    subscription = Subscription.find_by_external_customer_id(params["data"]["object"]["id"])

    if subscription
      subscription.destroy
    end

    head :ok, content_type: "text/html"
  end

  def stripe_failed
    puts Colorize.cyan(params)

    subscription = Subscription.find_by_stripe_customer_id(params["data"]["object"]["source"]["customer"])

    if params["type"].include? "failed"

      event = Event.new
      if subscription.fail_count > 0
        event.name = "Retry Transaction"
        event.event_type = "retry_transaction"
        event.event_lines = [{
          successful: true,
          text: "Subscription # #{subscription.id} retried and failed."
        }]
      else
        event.name = "Failed Transaction"
        event.event_type = "failed"
        event.event_lines = [{
          successful: true,
          text: "Subscription # #{subscription.id} failed."
        }]
      end
      event.save

      subscription.fail_count += 1
      subscription.fail_message = params["data"]["object"]["failure_message"]
      subscription.save

      # qw12

    elsif params["type"].include? "succeeded"

      if subscription.fail_count > 0
        subscription.fail_count = 0
        subscription.fail_message = ""
        subscription.save

        event = Event.new
        event.name = "Retry Transaction"
        event.event_type = "retry_transaction"
        event.event_lines = [{
          successful: true,
          text: "Subscription # #{subscription.id} retried and succeeded."
        }]

        event.save
      end

    end

    head :ok, content_type: "text/html"
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

    def isWebhookValid()
      secret = '< secret client token here >'
      body = '< request body here >'
      recieved_digest = '< Hmac-Sha256 value from webhook response header here >'

      calculated_digest = Digest::SHA256.hexdigest(secret+body)

      print(calculated_digest +"\n")
      print(recieved_digest +"\n\n")
      if calculated_digest == recieved_digest
        print("VALIDATION SUCCESS!\n")
        return true
      else
        print("Oops! There may be some third party interference going on.\n")
        return false
      end
    end

end