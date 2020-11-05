# frozen_string_literal: true

require "uri"
require "cgi"
require "openssl"
require "base64"

module URLSignature
  require "url_signature/version"
  require "url_signature/url"

  InvalidURL = Class.new(StandardError)
  ExpiredURL = Class.new(StandardError)
  InvalidSignature = Class.new(StandardError)

  HMAC_PROC = lambda do |key, data|
    Base64.urlsafe_encode64(
      OpenSSL::HMAC.digest("SHA256", key, data.to_s),
      padding: false
    )
  end

  # Create a new signed url.
  def self.call(
    url,
    key:,
    params: {},
    expires: 0,
    signature_param: "signature",
    expires_param: "expires",
    hmac_proc: HMAC_PROC
  )
    expires = expires.to_i
    params[expires_param] = expires if expires.positive?
    url = build_url(url, params)
    signature = hmac_proc.call(key, url)
    url.add_query(signature_param, signature)
    url.to_s
  end

  def self.verified?(
    url,
    key:,
    expires_param: "expires",
    signature_param: "signature",
    hmac_proc: HMAC_PROC
  )
    verify!(
      url,
      key: key,
      hmac_proc: hmac_proc,
      expires_param: expires_param,
      signature_param: signature_param
    )
  rescue InvalidSignature, InvalidURL, ExpiredURL
    false
  end

  def self.verify!( # rubocop:disable Metrics/MethodLength
    url,
    key:,
    hmac_proc: HMAC_PROC,
    expires_param: "expires",
    signature_param: "signature"
  )
    url = build_url(url)
    actual_url = url.to_s

    url.remove_query(signature_param)

    expected_url = call(
      url.to_s,
      key: key,
      expires_param: expires_param,
      hmac_proc: hmac_proc,
      signature_param: signature_param
    )

    expires = url.params[expires_param]&.first.to_i

    raise ExpiredURL if expires.positive? && expires < Time.now.to_i
    raise InvalidSignature unless actual_url == expected_url

    true
  end

  class << self
    private def build_url(url, params = {})
      url = URL.new(url)
      params.each {|name, value| url.add_query(name, value) }
      url
    end
  end
end

SignedURL = URLSignature
