# Building blocks for transactional emails. Email clients ignore stylesheets,
# so everything is inline and table-free where we can get away with it.
module MailerHelper
  BRAND = "#4f3bcb".freeze

  # A big tappable link that looks like the app's primary button.
  def email_button(label, url)
    link_to label, url, style: "display:inline-block;background:#{BRAND};color:#ffffff;font-weight:600;" \
                               "font-size:16px;line-height:1;text-decoration:none;padding:14px 22px;border-radius:10px;"
  end

  def email_paragraph(&block)
    tag.p(capture(&block), style: "margin:0 0 16px;font-size:16px;line-height:1.6;color:#15173a;")
  end

  def email_small(&block)
    tag.p(capture(&block), style: "margin:16px 0 0;font-size:14px;line-height:1.5;color:#5f6386;")
  end
end
