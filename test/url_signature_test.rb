# frozen_string_literal: true

require "test_helper"

class URLSignatureTest < Minitest::Test
  test "creates signed url using query string" do
    url = "https://example.com?c=2&b=hello%20there&a=1&d%5B%5D=1&d%5B%5D=2&" \
          "e[a]=1&e[b]=2#fragment"
    signed_url = SignedURL.call(url, key: "secret")

    expected_signed_url =
      "https://example.com/?a=1&b=hello%20there&c=2&d%5B%5D=1&" \
      "d%5B%5D=2&e%5Ba%5D=1&e%5Bb%5D=2&signature=" \
      "JQ96fn7u3W9SpdchRIUDRaNtXbjZ0FdL3w8plpJ7qdE#fragment"

    assert_equal expected_signed_url, signed_url
    assert SignedURL.verified?(signed_url, key: "secret")
  end

  test "creates signed url using custom HMAC algorithm" do
    hmac_proc = lambda do |key, data|
      Base64.urlsafe_encode64(
        OpenSSL::HMAC.digest("sha1", key, data.to_s),
        padding: false
      )
    end

    url = "https://example.com"
    signed_url = SignedURL.call(url, key: "secret", hmac_proc: hmac_proc)

    expected_signed_url =
      "https://example.com/?signature=7Zu2q3-Yuys1453XZfbD3zli83I"

    assert_equal expected_signed_url, signed_url
    assert SignedURL.verified?(signed_url, key: "secret", hmac_proc: hmac_proc)
  end

  test "creates signed url using HMAC that checks only path + query" do
    hmac_proc = lambda do |key, data|
      data = [data.path, ("?#{data.query}" if data.query)].compact.join

      Base64.urlsafe_encode64(
        OpenSSL::HMAC.digest("sha1", key, data),
        padding: false
      )
    end

    signed_url = SignedURL.call(
      "https://example.com/?a=1",
      key: "secret",
      hmac_proc: hmac_proc
    )

    urls = [
      signed_url,
      signed_url.gsub("example.com", "example.org")
    ]

    assert_equal 2, urls.uniq.size

    urls.each do |url|
      assert SignedURL.verified?(url, key: "secret", hmac_proc: hmac_proc),
             "Expected #{url.inspect} to be verified"
    end
  end

  test "creates signed url using custom signature param name" do
    url = "https://example.com"
    signed_url = SignedURL.call(url, key: "secret", signature_param: "s")

    expected_signed_url =
      "https://example.com/?s=x3HrJBBBkjnNdO8_R2duLqsK4XLxw9RL4xIZ9Qib-vw"

    assert_equal expected_signed_url, signed_url
    assert SignedURL.verified?(signed_url, key: "secret", signature_param: "s")
  end

  test "creates signed url using custom expires param name" do
    url = "https://example.com"
    expires = 2_000_000_000
    signed_url = SignedURL.call(
      url,
      key: "secret",
      expires: expires,
      expires_param: "until"
    )

    expected_signed_url =
      "https://example.com/?signature=Ndl1EG9QXA7ukSZSKSz1DKv8Mohj666cLBnq1-" \
      "XyDP4&until=#{expires}"

    assert_equal expected_signed_url, signed_url
    assert SignedURL.verified?(
      signed_url,
      key: "secret",
      expires_param: "until"
    )
  end

  test "rejects tempered urls" do
    signed_url = SignedURL.call(
      "https://example.com",
      key: "secret"
    )

    refute SignedURL.verified?("#{signed_url}&a=1", key: "secret")
    assert_raises(URLSignature::InvalidSignature) do
      SignedURL.verify!("#{signed_url}&a=1", key: "secret")
    end
  end

  test "rejects expired urls" do
    signed_url = SignedURL.call(
      "https://example.com",
      key: "secret",
      expires: Time.now.to_i - 1
    )

    refute SignedURL.verified?(signed_url, key: "secret")

    assert_raises(URLSignature::ExpiredURL) do
      SignedURL.verify!(signed_url, key: "secret")
    end
  end

  test "verifies fresh urls" do
    signed_url = SignedURL.call(
      "https://example.com",
      key: "secret",
      expires: Time.now.to_i + 5
    )

    assert SignedURL.verified?(signed_url, key: "secret")
  end

  test "accepts time objects as expiration time" do
    signed_url = SignedURL.call(
      "https://example.com",
      key: "secret",
      expires: Time.at(2_000_000_000)
    )

    assert_includes signed_url, "expires=2000000000"
    assert SignedURL.verified?(signed_url, key: "secret")
  end
end
