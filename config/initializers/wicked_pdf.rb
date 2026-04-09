# config/initializers/wicked_pdf.rb
if Rails.env.production?
  WickedPdf.configure do |config|
    config.exe_path = "/usr/local/bin/wkhtmltopdf" # Adjust this path if wkhtmltopdf is installed elsewhere
  end
else
  WickedPdf.configure do |config|
    config.exe_path = Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf")
  end
end
