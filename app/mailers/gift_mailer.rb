class GiftMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)

  default to: 'dustin@wittycreative.com'
  # default to: 'travis@wittycreative.com'

  def gift_email(line_item)

    @line_item = line_item

    attachments['gift_certificate.pdf'] = WickedPdf.new.pdf_from_string(
      render_to_string('gifts/view_pdf.html.erb'),
      orientation: 'Landscape',
      zoom: 1.8
    )

    mail(to: @line_item["properties"].select{|p| p["name"] == "RecipientEmail"}.first["value"], from: 'cleanchoiceenergy@no-reply.com', subject: 'A gift for you')

  end

end