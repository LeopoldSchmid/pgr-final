module ApplicationHelper
  def format_journal_content(content)
    return '' if content.blank?
    
    # First apply simple_format for line breaks and paragraphs
    formatted_content = simple_format(content)
    
    # Then auto-link URLs with a simple regex
    auto_link_urls(formatted_content)
  end

  private

  def auto_link_urls(text)
    url_regex = %r{
      \b
      (
        https?://[^\s<>"{}|\\^`\[\]]+[^\s<>"{}|\\^`\[\].,;:!?]
      )
    }ix

    text.gsub(url_regex) do |url|
      link_to(url, url, 
              target: '_blank', 
              rel: 'noopener noreferrer',
              class: 'text-blue-600 hover:text-blue-800 underline break-all')
    end.html_safe
  end
end
