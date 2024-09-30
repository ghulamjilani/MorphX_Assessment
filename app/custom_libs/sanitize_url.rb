# frozen_string_literal: false

# https://github.com/jarrett/sanitize-url
# Helper methods in this module are module methods so that they won't
# pollute the namespace into which the module is mixed in.
class SanitizeUrl
  ALPHANUMERIC_CHAR_CODES = (48..57).to_a + (65..90).to_a + (97..122).to_a

  VALID_OPAQUE_SPECIAL_CHARS = ['!', '*', "'", '(', ')', ';', ':', '@', '&', '=', '+', '$', ',', '/', '?', '%', '#', '[', ']', '-', '_', '.', '~'].freeze
  VALID_OPAQUE_SPECIAL_CHAR_CODES = VALID_OPAQUE_SPECIAL_CHARS.collect { |c| c[0].is_a?(String) ? c.ord : c[0] }
  VALID_OPAQUE_CHAR_CODES = ALPHANUMERIC_CHAR_CODES + VALID_OPAQUE_SPECIAL_CHAR_CODES

  VALID_SCHEME_SPECIAL_CHARS = ['+', '.', '-'].freeze
  VALID_SCHEME_SPECIAL_CHAR_CODES = VALID_SCHEME_SPECIAL_CHARS.collect { |c| c[0].is_a?(String) ? c.ord : c[0] }
  VALID_SCHEME_CHAR_CODES = ALPHANUMERIC_CHAR_CODES + VALID_SCHEME_SPECIAL_CHAR_CODES

  HTTP_STYLE_SCHEMES = ['http', 'https', 'ftp', 'ftps', 'svn', 'svn+ssh', 'git'].freeze # Common schemes whose format should be "scheme://" instead of "scheme:"

  class << self
    def dereference_numerics(str) # :nodoc:
      # Decimal code points, e.g. &#106; &#106 &#0000106; &#0000106
      str = str.gsub(/&#([a-fA-f0-9]+);?/) do
        char_or_url_encoded(Regexp.last_match(1).to_i)
      end
      # Hex code points, e.g. &#x6A; &#x6A
      str.gsub(/&#[xX]([a-fA-f0-9]+);?/) do
        char_or_url_encoded(Regexp.last_match(1).to_i(16))
      end
    end

    # Return either the literal char or the URL-encoded equivalent,
    # depending on our normalization rules. Requires a decimal
    # code point. Code point can be outside the single-byte range.
    def char_or_url_encoded(code) # :nodoc:
      if url_encode?(code)
        utf_8_str = [code.to_i].pack('U')
        length = utf_8_str.respond_to?(:bytes) ? utf_8_str.bytes.to_a.length : utf_8_str.length
        "%#{utf_8_str.unpack('H2' * length).join('%').upcase}"
      else
        code.chr
      end
    end

    # Should we URL-encode the byte?
    # Must receive an integer code point
    def url_encode?(code) # :nodoc:
      !(
        (code >= 48 and code <= 57)  or   # Numbers
        (code >= 65 and code <= 90)  or   # Uppercase
        (code >= 97 and code <= 122) or   # Lowercase
        VALID_OPAQUE_CHAR_CODES.include?(code)
      )
    end

    # Sanitize the URL. Example usage:
    #   sanitize_url('javascript:alert("XSS")')
    #   sanitize_url('javascript:alert("XSS")', :replace_evil_with => 'Replaced')
    #   sanitize_url('ftp://example.com', :schemes => ['http', 'https'])
    def sanitize_url(url, options = {})
      raise(ArgumentError, 'options[:schemes] must be an array') if options.key?(:schemes) && !options[:schemes].is_a?(Array)

      options = {
        :replace_evil_with => '',
        :default_scheme => 'https',
        :schemes => ['http', 'https', 'ftp', 'ftps', 'mailto', 'svn', 'svn+ssh', 'git']
      }.merge(options)

      url = dereference_numerics(url).strip

      # Schemes can consist of letters, digits, or any of the following special chars: + . -
      # The scheme must begin with a letter and be terminated by a colon.
      # Everything after the scheme is opaque for our purposes. (See http://www.w3.org/DesignIssues/Axioms.html#opaque)

      # Try to match a URI with a scheme. We check for percent-encoded characters in the scheme.
      url =~ /^(.+?)(:|%3A)(.*)$/
      dirty_scheme = Regexp.last_match(1)
      if dirty_scheme
        unescaped_opaque = Regexp.last_match(3)
        return options[:replace_evil_with].dup if unescaped_opaque.blank? || unescaped_opaque.match(%r{^/+$})
      else
        # Use http as the best guest, and the rest of the URL will be considered opaque
        dirty_scheme = options[:default_scheme].dup
        unescaped_opaque = url
      end
      # Remove URL encoding from the scheme
      dirty_scheme.gsub!(/%([a-zA-Z0-9]{2})/) do
        code = Regexp.last_match(1).to_i(16)
        VALID_SCHEME_CHAR_CODES.include?(code) ? code.chr : ''
      end

      # Clean the scheme by removing invalid characters
      scheme = ''
      dirty_scheme.each_byte do |code|
        scheme << code.chr if VALID_SCHEME_CHAR_CODES.include?(code)
      end

      # URL-encode the opaque portion as necessary. Only encode those bytes that are absolutely not allowed in URLs.
      opaque = ''
      unescaped_opaque.each_byte do |code|
        if url_encode?(code)
          opaque << '%' << code.to_s(16).upcase
        else
          opaque << code.chr
        end
      end

      if options[:schemes].collect(&:to_s).include?(scheme.downcase)
        if HTTP_STYLE_SCHEMES.include?(scheme.downcase) && !opaque.match(%r{^//})
          # It's an HTTP-like scheme, but the two slashes are missing. We'll fix that as a courtesy.
          "#{scheme}://#{opaque}"
        else
          # Either the scheme doesn't need the two slashes, or the opaque portion already has them.
          "#{scheme}:#{opaque}"
        end
      else
        options[:replace_evil_with].dup
      end
    end
  end
end
