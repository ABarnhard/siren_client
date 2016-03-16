module SirenClient
  module Modules
    module WithRawResponse
      def initialize
        @_next_response_is_raw = false
      end

      def with_raw_response
        @_next_response_is_raw = true
        self
      end

      def disable_raw_response
        @_next_response_is_raw = false
      end

      def next_response_is_raw?
        @_next_response_is_raw
      end

      private 

      def generate_raw_response(url, config)
        RawResponse.new HTTParty.get(url, config)
      end
    end
  end
end
