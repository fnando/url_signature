# frozen_string_literal: true

require "test_helper"

class URLTest < Minitest::Test
  test "rejects non-http uris" do
    assert_raises(URLSignature::InvalidURL) do
      URLSignature::URL.new("example.com")
    end
  end

  test "parses basic http url" do
    url = URLSignature::URL.new("http://example.com")

    assert_equal "http://example.com/", url.to_s
  end

  test "parses basic https url" do
    url = URLSignature::URL.new("https://example.com")

    assert_equal "https://example.com/", url.to_s
  end

  test "normalizes port" do
    assert_equal "https://example.com/",
                 URLSignature::URL.new("https://example.com:443").to_s
    assert_equal "http://example.com/",
                 URLSignature::URL.new("http://example.com:80").to_s
    assert_equal "https://example.com:4343/",
                 URLSignature::URL.new("https://example.com:4343").to_s
    assert_equal "http://example.com:8080/",
                 URLSignature::URL.new("http://example.com:8080").to_s
  end

  test "parses fragment" do
    assert_equal "https://example.com/#fragment",
                 URLSignature::URL.new("https://example.com/#fragment").to_s

    assert_equal "https://example.com/",
                 URLSignature::URL.new("https://example.com/").to_s
  end

  test "parses query string" do
    assert_equal "https://example.com/?a=1&b=2&d%5B%5D=3&d%5B%5D=4",
                 URLSignature::URL.new(
                   "https://example.com?b=2&d%5B%5D=4&d%5B%5D=3&a=1"
                 ).to_s
  end

  test "adds new query" do
    url = URLSignature::URL.new("https://example.com")
    url.add_query("message", "hello world")

    assert_equal "https://example.com/?message=hello%20world", url.to_s

    url.add_query("message", "a new hello world")

    assert_equal "https://example.com/?message=a%20new%20hello%20world",
                 url.to_s

    url.clear_query!
    url.add_query "a", nil

    assert_equal "https://example.com/?a=", url.to_s

    url.clear_query!
    url.add_query("a[]", 1)
    url.add_query("a[]", 2, replace: false)
    url.add_query("a[]", [3, 4], replace: false)

    assert_equal "https://example.com/?a%5B%5D=1&a%5B%5D=2&a%5B%5D=3&a%5B%5D=4",
                 url.to_s

    url.clear_query!
    url.add_query("a[hello]", "hello")
    url.add_query("a[hi]", "hi")

    assert_equal "https://example.com/?a%5Bhello%5D=hello&a%5Bhi%5D=hi",
                 url.to_s
  end

  test "rejects non-qualified urls" do
    error = assert_raises(URLSignature::InvalidURL) do
      URLSignature::URL.new("example.com")
    end

    assert_equal "example.com must be a fully qualified URL (http/https)",
                 error.message
  end

  test "rejects invalid urls" do
    error = assert_raises(URLSignature::InvalidURL) do
      URLSignature::URL.new("\\")
    end

    assert_equal "\\ must be a fully qualified URL (http/https)",
                 error.message
  end
end
