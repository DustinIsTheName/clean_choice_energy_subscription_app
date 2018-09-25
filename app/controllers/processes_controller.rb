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

    Import.destroy_all
    Transaction.destroy_all

    import = Import.new
    import.transaction_count = csv.count
    import.save

    csv.each do |row|
      row = row.to_hash

      puts row["First Name"]
      puts row["Last Name"]
      puts row["Credit Card #"]
      puts row["Credit Card #"].to_s.slice(-4,4)

      transaction = Transaction.new
      subscription = Subscription.find_by({first_name: row["First Name"]&.strip, last_name: row["Last Name"]&.strip, cc_number: row["Credit Card #"].to_s.strip.slice(-4,4)})
      error_codes = []

      transaction.no_retry = false
      unless row["Subscription Product"].blank?
        begin
          product = ShopifyAPI::Product.find(row["Subscription Product"])
        rescue => e
          error_codes << 'Product not found'
        end
      end

      puts subscription

      unless subscription
        subscription = Subscription.new
        ################################################################################
        # Use the provided ID to get the product from Shopify. - Shopify
        ################################################################################

        if row["Email"].blank?
          ################################################################################
          # Create Stripe token and Customer - Stripe
          ################################################################################
          begin
            expiration = row["Credit Card Expiration (MM/YY)"].split('/')
            stripe_token = Stripe::Token.create(
              :card => {
                :number => row["Credit Card #"],
                :exp_month => expiration[0],
                :exp_year => expiration[1]
              },
            )

            stripe_customer = Stripe::Customer.create(
              :description => "Customer for jenny.rosen@example.com",
              :source => stripe_token
            )
          rescue => e
            error_codes << e.message
            puts Colorize.orange('Stripe Error - Token or Customer')
            puts e.message
          end

          ################################################################################
          # Create Stripe Plan and Subscription using the created Customer. - Stripe
          ################################################################################
          begin
            if stripe_token and product
              stripe_plan = Stripe::Plan.create(
                :amount => (product.variants.first.price.to_f * 100).floor,
                :interval => "month",
                :product => {
                  :name => product.title
                },
                :currency => "usd"
              )

              stripe_subscription = Stripe::Subscription.create(
                :customer => stripe_customer.id,
                :items => [
                  {
                    :plan => stripe_plan.id,
                  },
                ]
              )
            end
          rescue => e
            error_codes << e.message
            puts Colorize.orange('Stripe Error - Plan and Subscription')
            puts e.message
          end
        else # row["Email"].blank?
          ################################################################################
          # Create ReCharge Customer and Address. - ReCharge
          ################################################################################
          begin
            ########### recharge_customer
            url = URI("https://api.rechargeapps.com/customers")

            address2 = row["Street Address 2"] ||= ""

            customer_params = {
              "email": row["Email"],
              "first_name": row["First Name"]&.strip,
              "last_name": row["Last Name"]&.strip,
              "billing_first_name": row["First Name"],
              "billing_last_name": row["Last Name"],
              "billing_address1": row["Street Address"],
              "billing_address2": address2,
              "billing_zip": row["Zip"],
              "billing_city": row["City"],
              "billing_province": row["State"],
              "billing_country": "United States",
              "billing_phone": "1-800-555-1234"
            }

            recharge_customer = recharge_http_request(url, customer_params)

            puts Colorize.bright('recharge_customer')
            puts Colorize.bright(recharge_customer)

            ########### recharge_address
            if recharge_customer["customer"]
              url = URI("https://api.rechargeapps.com/customers/#{recharge_customer["customer"]["id"]}/addresses")

              address_params = {
                "address1": row["Street Address"],
                "address2": address2,
                "city": row["City"],
                "province": row["State"],
                "first_name": recharge_customer["customer"]["first_name"]&.strip,
                "last_name": recharge_customer["customer"]["last_name"]&.strip,
                "zip": row["Zip"],
                "country": "United States",
                "phone": "1-800-555-1234"
              }
            elsif recharge_customer["errors"]
              recharge_customer["errors"].each do |error_message|
                error_codes << error_message.last
              end
            end

            recharge_address = recharge_http_request(url, address_params)

            if recharge_address["errors"]
              recharge_address["errors"].each do |error_message|
                error_codes << error_message.last
              end
            end

            puts Colorize.bright('recharge_address')
            puts Colorize.bright(recharge_address)
          rescue => e
            error_codes << e.message
            puts Colorize.orange('ReCharge Error - Customer and Address')
            puts e.message
          end

          ################################################################################
          # Create Stripe token and Customer to pass to ReCharge - Stripe
          ################################################################################
          begin
            if row["Credit Card Expiration (MM/YY)"]
              expiration = row["Credit Card Expiration (MM/YY)"].split('/')
              stripe_token = Stripe::Token.create(
                :card => {
                  :number => row["Credit Card #"],
                  :exp_month => expiration[0],
                  :exp_year => expiration[1]
                },
              )

              stripe_customer = Stripe::Customer.create(
                :description => "Customer for jenny.rosen@example.com",
                :source => stripe_token
              )
            else
              error_codes << "Credit Card Expiration can't be blank"
            end
          rescue => e
            error_codes << e.message
            puts Colorize.orange('Stripe Error for ReCharge')
            puts e.message
          end

          ################################################################################
          # Create ReCharge Subscription with created Customer and Address and Stripe token. - ReCharge
          ################################################################################

          begin
            if stripe_customer and recharge_address["address"] and product

              url = URI("https://api.rechargeapps.com/subscriptions")

              current_time = Time.now
              if current_time.mday > 28
                current_time = current_time.at_beginning_of_month.next_month
              end

              subscription_params = {
                "address_id": recharge_address["address"]["id"],
                "next_charge_scheduled_at": (current_time + 600).strftime('%Y-%m-%dT%H:%M:%S'),
                "product_title": product.title,
                "price": product.variants.first.price,
                "quantity": 1,
                "shopify_variant_id": product.variants.first.id,
                "order_interval_unit": "month",
                "order_interval_frequency": "1",
                "order_day_of_month": current_time.mday,
                "charge_interval_frequency": "1",
                "stripe_customer_token": stripe_customer.id
              }

              recharge_subscription = recharge_http_request(url, subscription_params)

              if recharge_subscription["errors"]
                recharge_subscription["errors"].each do |error_message|
                  error_codes << error_message.last
                end
              end

              puts Colorize.bright('recharge_subscription')
              puts Colorize.bright(recharge_subscription)
            end
          rescue => e
            error_codes << e.message
            puts Colorize.orange('ReCharge Error - Subscription')
            puts e.message
          end

        end # row["Email"].blank?
      else
        error_codes << "Customer already has subscription"
        transaction.no_retry = true
      end

      ################################################################################
      # Begin setting up the Transaction and Subscription information - Subscription/Transaction
      ################################################################################
      ######### Name Fields
      unless row["First Name"].blank? and row["Last Name"].blank?
        transaction.name = ''
        unless row["First Name"].blank?
          transaction.name = row["First Name"].strip
          subscription.first_name = row["First Name"].strip
        else
          error_codes << "First Name can't be blank"
        end
        unless row["First Name"].blank? or row["Last Name"].blank?
          transaction.name += ' '
        end
        unless row["Last Name"].blank?
          transaction.name += row["Last Name"].strip
          subscription.last_name = row["Last Name"].strip
        else
          error_codes << "Last Name can't be blank"
        end
      end

      ######### Email Field
      transaction.email = row["Email"]
      subscription.email = row["Email"]

      ######### Product Info Fields
      if product
        transaction.product = product.id
        transaction.amount = product.variants.first.price

        subscription.product = product.id
      else
        error_codes << 'Product not found'
      end

      ######### Credit Card Field
      unless row["Credit Card #"].blank?
        transaction.cc_number = row["Credit Card #"].to_s.slice(-4,4)
        subscription.cc_number = row["Credit Card #"].to_s.slice(-4,4)
      else
        error_codes << "No credit card number"
      end

      ######### Import Relation
      transaction.import_id = import.id

      if stripe_customer
        subscription.external_customer_id = stripe_customer.id
      elsif recharge_customer
        if recharge_customer["customer"]
          subscription.external_customer_id = recharge_customer["customer"]["id"]
        end
      end

      if stripe_subscription
        subscription.external_id = stripe_subscription.id
        subscription.payment_service = 'stripe'
      elsif recharge_subscription
        if recharge_subscription["subscription"]
          subscription.external_id = recharge_subscription["subscription"]["id"]
          subscription.payment_service = 'recharge'
        elsif recharge_subscription["errors"]
          recharge_subscription["errors"].each do |error_message|
            error_codes << error_message.first.to_s + ' ' + error_message.last
          end
        end
      end

      ################################################################################
      # Organize Address Information - Subscription
      ################################################################################
      unless row["Street Address"].blank? or row["City"].blank? or row["State"].blank? or row["Zip"].blank?
        subscription.address = {
          street_address: row["Street Address"],
          street_address_2: row["Street Address 2"],
          city: row["City"],
          state: row["State"],
          zip: row["Zip"]
        }
      else
        if row["Street Address"].blank?
          error_codes << "Street Address can't be blank"
        end  
        if row["City"].blank?
          error_codes << "City can't be blank"
        end
        if row["State"].blank?
          error_codes << "State can't be blank"
        end 
        if row["Zip"].blank?
          error_codes << "Zip can't be blank"
        end
      end

      ################################################################################
      # Check Error Codes
      ################################################################################
      if error_codes.size > 0
        transaction.status = false
        puts Colorize.red('errors present, so skip saving subscription')
      else
        ################################################################################
        # Save the Subscription and recored errors if they fail. - Subscription/Transaction
        ################################################################################
        if subscription.save
          ######### Set Transaction Status
          transaction.status = true
          puts Colorize.green('subscription saved')

          ShopifyOrder.delay.create(product, subscription)
        else
          ######### Set Transaction Status
          transaction.status = false
          subscription.errors.messages.each do |error_message|
            error_codes << (error_message.first.to_s << ' ' << error_message.last.first)
          end
          puts Colorize.red('subscription error')
        end
      end

      ################################################################################
      # Set Transaction error codes. - Transaction
      ################################################################################
      transaction.error_codes = error_codes

      ################################################################################
      # Save the Transaction. Simple enough. - Transaction
      ################################################################################
      if transaction.save
        puts Colorize.green('transaction saved')
      else
        puts Colorize.red('transaction error')
      end

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

  private

    def recharge_http_request(url, body = nil)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      if body
        request = Net::HTTP::Post.new(url)
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