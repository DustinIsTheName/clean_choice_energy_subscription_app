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

    import = Import.new
    import.save

    csv.each do |row|
      transaction = Transaction.new
      subscription = Subscription.new
      error_codes = []

      row = row.to_hash
      
      ################################################################################
      # Create Stripe token and Customer - Stripe
      ################################################################################
      begin
        expiration = row["Credit Card Expiration (MM/YY)"].split('/')
        token = Stripe::Token.create(
          :card => {
            :number => row["Credit Card #"],
            :exp_month => expiration[0],
            :exp_year => expiration[1]
          },
        )

        customer = Stripe::Customer.create(
          :description => "Customer for jenny.rosen@example.com",
          :source => token
        )
      rescue => e
        error_codes << e.message
        puts Colorize.orange('Stripe Error')
        puts e.message
      end

      ################################################################################
      # Use the provided ID to get the product from Shopify. - Shopify
      ################################################################################
      unless row["Subscription Product"].blank?
        begin
          product = ShopifyAPI::Product.find(row["Subscription Product"])
        rescue => e
          error_codes << 'Product not found'
        end
      end

      ################################################################################
      # Create Stripe Charge using the created Customer. - Stripe
      ################################################################################
      if token and product
        plan = Stripe::Plan.create(
          :amount => (product.variants.first.price.to_f * 100).floor,
          :interval => "month",
          :product => {
            :name => product.title
          },
          :currency => "usd"
        )

        stripe_subscription = Stripe::Subscription.create(
          :customer => customer.id,
          :items => [
            {
              :plan => plan.id,
            },
          ]
        )
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
          error_codes << "First Name Blank"
        end
        unless row["First Name"].blank? or row["Last Name"].blank?
          transaction.name += ' '
        end
        unless row["Last Name"].blank?
          transaction.name += row["Last Name"].strip
          subscription.last_name = row["Last Name"].strip
        else
          error_codes << "Last Name Blank"
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

      ######### Status
      transaction.status = 1
      ######### Import Relation
      transaction.import_id = import.id

      if stripe_subscription
        subscription.external_id = stripe_subscription.id
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
      # Save the Subscription and recored errors if they fail. - Subscription
      ################################################################################
      if subscription.save
        puts Colorize.green('subscription saved')
      else
        subscription.errors.messages.each do |error_message|
          error_codes << (error_message.first.to_s << ' ' << error_message.last.first)
        end
        puts Colorize.red('subscription error')
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

    event.save

    render json: import, :include => [:transactions]
  end

end