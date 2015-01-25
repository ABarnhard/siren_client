module SirenClient
  class HTTP
    include HTTParty
    format :json

    @@headers = { "User-Agent" => "SirenClient v#{SirenClient::VERSION}" }

    def self.headers; @@headers; end
    def self.headers=(headers={})
      return unless headers.is_a? Hash
      # Ensure the header keys are strings.
      headers.reject! { |k,v| k == "User-Agent" }
      @@headers.merge!(headers)
      nil
    end

    def self.call(method, url, params)
      dmethod = method.downcase
      self.class.send(dmethod, url, { 
        headers: self.convert_hash_keys(@@headers.merge(params[:headers] || params['headers'] || {})), 
        query: params[:query], 
        body: params[:body] 
      })
  end

  private

  def self.convert_hash_keys(hash)
    headers.inject({}) { |h,(k,v)| h[k.to_s] = v; h }
  end
end
