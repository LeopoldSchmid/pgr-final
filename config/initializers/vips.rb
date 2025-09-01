# Configure VIPS to suppress openslide warnings and set up proper error handling
if defined?(Vips)
  # Set up error handling for missing VIPS modules
  begin
    # Test VIPS functionality
    Vips::Image.black(1, 1)
  rescue => e
    Rails.logger.warn "VIPS warning: #{e.message}"
  end
end