# frozen_string_literal: true

require "uri"
require "cgi"
require "openssl"

module URLSignature
  require "url_signature/version"
  require "url_signature/url"

  InvalidURL = Class.new(StandardError)
  ExpiredURL = Class.new(StandardError)
  InvalidSignature = Class.new(StandardError)

  # Create a new signed url.
  def self.call(
    url,
    key:,
    params: {},
    expires: 0,
    signature_param: "signature",
    expires_param: "expires",
    algorithm: "SHA256"
  )
    expires = expires.to_i
    params[expires_param] = expires if expires.positive?
    url = build_url(url, params)
    signature = OpenSSL::HMAC.hexdigest(algorithm, key, url.to_s)
    url.add_query(signature_param, signature)
    url.to_s
  end

  def self.verified?(
    url,
    key:,
    algorithm: "SHA256",
    expires_param: "expires",
    signature_param: "signature"
  )
    verify!(
      url,
      key: key,
      algorithm: algorithm,
      expires_param: expires_param,
      signature_param: signature_param
    )
  rescue InvalidSignature, InvalidURL, ExpiredURL
    false
  end

  def self.verify!(
    url,
    key:,
    algorithm: "SHA256",
    expires_param: "expires",
    signature_param: "signature"
  )
    url = build_url(url)
    actual_signature, * = url.remove_query(signature_param)
    expected_signature = OpenSSL::HMAC.hexdigest(algorithm, key, url.to_s)

    expires = url.params[expires_param]&.first.to_i

    raise ExpiredURL if expires.positive? && expires < Time.now.to_i
    raise InvalidSignature unless actual_signature == expected_signature

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
