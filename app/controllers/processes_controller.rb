class ProcessesController < ApplicationController

  def import
    puts params

    csv_text = File.read(params["CsvDoc"].path)
    csv = CSV.parse(csv_text, :headers => true)

    import = Import.new
    import.save

    csv.each do |row|
      transaction = Transaction.new
      subscription = Subscription.new
      error_codes = []

      row = row.to_hash

      # Use the provided ID to get the product from Shopify.
      unless row["Subscription Product"].blank?
        begin
          product = ShopifyAPI::Product.find(row["Subscription Product"])
        rescue => e
          error_codes << 'Product not found'
        end
      end

      # Begin setting up the Transaction and Subscription information.
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

      transaction.email = row["Email"]
      subscription.email = row["Email"]

      if product
        transaction.product = product.id
        transaction.amount = product.variants.first.price

        subscription.product = product.id
      else
        error_codes << 'Product not found'
      end
      unless row["Credit Card #"].blank?
        transaction.cc_number = row["Credit Card #"].to_s.slice(-4,4)
        subscription.cc_number = row["Credit Card #"].to_s.slice(-4,4)
      else
        error_codes << "No credit card number"
      end
      transaction.status = 1
      transaction.import_id = import.id

      # Organize Address information
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

      if subscription.save
        puts Colorize.green('subscription saved')
      else
        subscription.errors.messages.each do |error_message|
          error_codes << (error_message.first.to_s << ' ' << error_message.last.first)
        end
        puts Colorize.red('subscription error')
      end

      transaction.error_codes = error_codes

      # Save the Transaction. Simple enough.
      if transaction.save
        puts Colorize.green('transaction saved')
      else
        puts Colorize.red('transaction error')
      end

    end

    render json: import, :include => [:transactions]
  end

end