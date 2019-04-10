class GiftMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)

  default to: 'dustin@wittycreative.com'
  # default to: 'travis@wittycreative.com'

  def gift_email(line_item)

    @line_item = line_item

    if Rails.env.production?
      zoom = 1
    else
      zoom = 9.0
    end

    attachments['gift_certificate.pdf'] = WickedPdf.new.pdf_from_string(
      render_to_string('gifts/view_pdf.html.erb'),
      orientation: 'Landscape',
      page_size: 'Letter',
      zoom: zoom,
      margin: {
        top: 0,
        bottom: 0,
        left: 0,
        right: 0
      }
    )

    mail(to: @line_item["properties"].select{|p| p["name"] == "RecipientEmail"}.first["value"], from: 'cleanchoiceenergy@no-reply.com', subject: 'A gift for you')

  end

  def valentine_gift_email(line_item)

    @line_item = line_item

    if Rails.env.production?
      zoom = 1
    else
      zoom = 9.0
    end

    attachments['gift_certificate.pdf'] = WickedPdf.new.pdf_from_string(
      render_to_string('gifts/view_pdf.html.erb'),
      orientation: 'Landscape',
      page_size: 'Letter',
      zoom: zoom,
      margin: {
        top: 0,
        bottom: 0,
        left: 0,
        right: 0
      }
    )

    mail(to: @line_item["properties"].select{|p| p["name"] == "RecipientEmail"}.first["value"], from: 'support@cleanchoiceenergy.com', subject: 'A gift for you')

  end

  def earth_day_gift_email(line_item, buyer_email, first_name, last_name)

    @first_name = first_name
    @last_name = last_name
    @line_item = line_item

    if Rails.env.production?
      zoom = 1
    else
      zoom = 9.0
    end

    attachments['gift_certificate.pdf'] = WickedPdf.new.pdf_from_string(
      render_to_string('gifts/view_pdf.html.erb'),
      orientation: 'Landscape',
      page_size: 'Letter',
      zoom: zoom,
      margin: {
        top: 0,
        bottom: 0,
        left: 0,
        right: 0
      }
    )

    mail(to: buyer_email, from: 'cleanchoiceenergy@no-reply.com', subject: 'Thank you for supporting our forests.')

  end

end