class SessionsController < Devise::SessionsController
  def destroy
    puts Colorize.red("destroy Session")
    if current_user
      puts Colorize.blue("in user")
      import = current_user.import

      if import
        import.transactions.destroy_all
        import.destroy
      end
    end

    super
  end
end