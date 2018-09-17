class ProcessesController < ApplicationController

  def import
    puts params

    csv_text = File.read(params["CsvDoc"].path)
    csv = CSV.parse(csv_text, :headers => true)
    array = []

    import = Import.new
    import.save

    csv.each do |row|
      transaction = Transaction.new
      subscription = Subscription.new

      row = row.to_hash
      array.append(row)

      unless row["Subscription Product"].blank?
        product = ShopifyAPI::Product.find(row["Subscription Product"])
      end

      puts Colorize.green(product)

      unless row["First Name"].blank? or row["Last Name"].blank?
        transaction.name = row["First Name"] << ' ' << row["Last Name"]
      end

      transaction.email = row["Email"]
      if product
        transaction.product = product.id
        transaction.amount = product.variants.first.price
      end
      unless row["Credit Card #"].blank?
        transaction.cc_number = row["Credit Card #"].slice(-4,4)
      end
      transaction.status = 1
      # transaction.error_codes = []
      transaction.import_id = import.id

      if transaction.save
        puts Colorize.green('transaction saved')
      else
        puts Colorize.green('transaction error')
      end

    end

    render json: import, :include => [:transactions]
  end

end