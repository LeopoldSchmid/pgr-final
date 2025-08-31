# config/initializers/wicked_pdf.rb
if Rails.env.production?
  WickedPdf.config = {
    exe_path: '/usr/local/bin/wkhtmltopdf' # Adjust this path if wkhtmltopdf is installed elsewhere
  }
else
  WickedPdf.config = {
    exe_path: Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')
  }
end