module LegalPagesHelper
  # A numbered-free policy section that also registers itself in the
  # "On this page" list the legal layout renders beside the text.
  def legal_section(title, id: title.parameterize, &block)
    (@legal_toc ||= []) << [ id, title ]
    tag.section(id: id, class: "scroll-mt-24", aria: { labelledby: "#{id}-heading" }) do
      tag.h2(title, id: "#{id}-heading") + capture(&block)
    end
  end

  def legal_toc
    @legal_toc || []
  end

  def legal_related_links
    [ [ "Privacy Policy", privacy_path ], [ "Terms of Service", terms_path ],
      [ "Refund & Cancellation Policy", refunds_path ], [ "Contact", contact_path ] ].reject { |_, path| current_page?(path) }
  end

  def support_mail_link(subject: nil)
    mail_to Legal.support_email, Legal.support_email, subject: subject
  end
end
