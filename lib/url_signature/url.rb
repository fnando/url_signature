# frozen_string_literal: true

module URLSignature
  class URL
    attr_reader :uri, :scheme, :host, :path, :user, :password, :fragment,
                :params
    private :uri

    SEQUENCIAL_PARAMS = Object.new

    def initialize(url)
      @uri = parse_url(url)
      @scheme = uri.scheme
      @host = uri.host
      @user = uri.user
      @password = uri.password
      @path = uri.path.empty? ? "/" : uri.path
      @params = parse_query(uri.query)
      @fragment = uri.fragment
    end

    def port
      return if uri.port == 80 && @scheme == "http"
      return if uri.port == 443 && @scheme == "https"

      uri.port
    end

    def add_query(key, value, replace: true)
      params[key] ||= []
      params[key] = [] if replace
      params[key] += [value].flatten.map(&:to_s)
    end

    def remove_query(key)
      params.delete(key) || []
    end

    def query
      return if params.empty?

      query = params.each_with_object([]) do |(param, value), buffer|
        if param.include?("[")
          value.each {|v| buffer << "#{encode(param)}=#{encode(v)}" }
        else
          buffer << "#{encode(param)}=#{encode(value.last)}"
        end
      end

      query.sort.join("&")
    end

    def clear_query!
      @params = {}
    end

    def to_s
      [
        "#{scheme}://#{host}",
        port ? ":#{port}" : nil,
        path,
        query ? "?#{query}" : nil,
        fragment ? "##{fragment}" : nil
      ].compact.join
    end

    private def encode(value)
      CGI.escape(value).gsub("+", "%20")
    end

    private def parse_query(query)
      Hash[CGI.parse(query.to_s).to_a]
    end

    private def parse_url(url)
      uri = URI(url)

      unless %w[URI::HTTPS URI::HTTP].include?(uri.class.name)
        raise_invalid_url_error(url)
      end

      uri
    rescue ::URI::InvalidURIError
      raise_invalid_url_error(url)
    end

    private def raise_invalid_url_error(url)
      raise InvalidURL, "#{url} must be a fully qualified URL (http/https)"
    end
  end
end
