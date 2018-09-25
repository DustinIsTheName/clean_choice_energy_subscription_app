module ApplicationHelper
  def body_class
    "#{controller_name}-#{controller.action_name}"
  end

  def get_product_name(product_id)
    if product_id == 1602140700714
      "Clean Furnace Plan"
    elsif product_id == 1602141356074
      "100% Clean Energy"
    else
      "-"
    end
  end

  def controller_name
    controller.controller_path.gsub('/','-')
  end

  def money(number)
    "$" + sprintf('%.2f', number) if number.is_a? Numeric
  end

  def dash_if_empty(content)
    if content
      content
    else
      "-"
    end
  end

  def active_link_to(name = nil, options = nil, html_options = {}, &block)
    active_class = html_options[:active] || "active"
    html_options.delete(:active)
    html_options[:class] = "#{html_options[:class]} #{active_class}" if current_page?(options)
    link_to(name, options, html_options, &block)
  end

  def empty_transaction_row
    transaction = Transaction.new({
      id: '',
      name: '',
      email: '',
      product: '',
      amount: '',
      cc_number: '',
      status: false,
      error_codes: []
    })

    ApplicationController.new.render_to_string(partial: '/partials/transaction_row', locals: {transaction: transaction})
  end
end
