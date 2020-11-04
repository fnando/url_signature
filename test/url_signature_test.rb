# frozen_string_literal: true

require "test_helper"

class URLSignatureTest < Minitest::Test
  test "creates signed url using query string" do
    url = "https://example.com?c=2&b=hello%20there&a=1&d%5B%5D=1&d%5B%5D=2&" \
          "e[a]=1&e[b]=2#fragment"
    signed_url = SignedURL.call(url, key: "secret")

    expected_signed_url =
      "https://example.com/?a=1&b=hello%20there&c=2&d%5B%5D=1&" \
      "d%5B%5D=2&e%5Ba%5D=1&e%5Bb%5D=2&signature=250f7a7e7eeed" \
      "d6f52a5d72144850345a36d5db8d9d0574bdf0f2996927ba9d1#fragment"

    assert_equal expected_signed_url, signed_url
    assert SignedURL.verified?(signed_url, key: "secret")
  end

  test "creates signed url using custom algorithm" do
    url = "https://example.com"
    signed_url = SignedURL.call(url, key: "secret", algorithm: "SHA1")

    expected_signed_url =
      "https://example.com/?signature=ed9bb6ab7f98bb2b35e39dd765f6c3df3962f372"

    assert_equal expected_signed_url, signed_url
    assert SignedURL.verified?(signed_url, key: "secret", algorithm: "SHA1")
  end

  test "creates signed url using custom signature param name" do
    url = "https://example.com"
    signed_url = SignedURL.call(url, key: "secret", signature_param: "s")

    expected_signed_url =
      "https://example.com/?s=" \
      "c771eb2410419239cd74ef3f47676e2eab0ae172f1c3d44be31219f5089bfafc"

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
      "https://example.com/?signature=35d975106f505c0eee912652292cf50cabfc" \
      "328863ebae9c2c19ead7e5f20cfe&until=#{expires}"

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
