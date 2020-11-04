<p align="center">
  <a href="https://github.com/fnando/url_signature/">
    <img width="400" src="https://github.com/fnando/url_signature/raw/main/url_signature.svg" alt="URL Signature">
  </a>
</p>

<p align="center">
  Create and verify signed urls. Supports expiration time.
</p>

<p align="center">
  <a href="https://github.com/fnando/url_signature"><img src="https://github.com/fnando/url_signature/workflows/Tests/badge.svg" alt="Tests"></a>
  <a href="https://codeclimate.com/github/fnando/url_signature"><img src="https://codeclimate.com/github/fnando/url_signature/badges/gpa.svg" alt="Code Climate"></a>
  <a href="https://rubygems.org/gems/url_signature"><img src="https://img.shields.io/gem/v/url_signature.svg" alt="Version"></a>
  <a href="https://rubygems.org/gems/url_signature"><img src="https://img.shields.io/gem/dt/url_signature.svg" alt="Downloads"></a>
</p>

## Installation

```bash
gem install url_signature
```

Or add the following line to your project's Gemfile:

```ruby
gem "url_signature"
```

## Usage

To create a signed url, you can use `SignedURL.call(url, **kwargs)`, where
arguments are:

- `key`: The secret key that will be used to generate the HMAC digest.
- `params`: Any additional params you want to add as query strings.
- `expires`: Any integer representing an epoch time. Urls won't be verified
  after this date. By default, urls don't expire.
- `algorithm`: The hashing algorithm that will be used. By default, SHA256 will
  be used.
- `signature_param`: The signature's param name. By default it's `signature`.
- `expires_param`: The expires' param name. By default it's `expires`.

```ruby
key = "secret"

signed_url = SignedURL.call("https://nandovieira.com", key: key)
#=> "https://nandovieira.com/?signature=87fdf44a5109c54edff2e0258b354e32ba5baf3dd21ec5af82f08b82ce362fbf"
```

You can use the method `SignedURL.verified?(url, **kwargs)` to verify if a
signed url is valid.

```ruby
key = "secret"

signed_url = SignedURL.call("https://nandovieira.com", key: key)

SignedURL.verified?(signed_url, key: key)
#=> true
```

Alternatively, you can use `SignedURL.verify!(url, **kwargs)`, which will raise
exceptions if a url cannot be verified (e.g. has been tampered, it's not fresh,
or is a plain invalid url).

- `URLSignature::InvalidURL` if url is not valid
- `URLSignature::ExpiredURL` if url has expired
- `URLSignature::InvalidSignature` if the signature cannot be verified

To create a url that's valid for a time window, use `:expires`. The following
example create a url that's valid for 2 minutes.

```ruby
key = "secret"

signed_url = SignedURL.call(
  "https://nandovieira.com",
  key: secret,
  expires: Time.now.to_i + 120
)
#=> "https://nandovieira.com/?expires=1604477596&signature=7ac5eaee20d316c6cd3f81db14cde98c3c669d423a32d2c546730cbb0dcbc6f2"
```

## Maintainer

- [Nando Vieira](https://github.com/fnando)

## Contributors

- https://github.com/fnando/url_signature/contributors

## Contributing

For more details about how to contribute, please read
https://github.com/fnando/url_signature/blob/main/CONTRIBUTING.md.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT). A copy of the license can be
found at https://github.com/fnando/url_signature/blob/main/LICENSE.md.

## Code of Conduct

Everyone interacting in the url_signature project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/fnando/url_signature/blob/main/CODE_OF_CONDUCT.md).
