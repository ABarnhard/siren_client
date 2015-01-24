module SirenClient
  class Entity
    attr_reader :payload, :classes, :properties, :entities, :rels, 
                :links, :actions, :title, :href, :type


    def initialize(data)
      if data.class == String
        unless data.class == String && data.length > 0
            raise InvalidURIError, 'An invalid url was passed to SirenClient::Entity.new.'
        end
        begin
            @payload = HTTP.get(data).parsed_response
        rescue URI::InvalidURIError => e
            raise InvalidURIError, e.message
        rescue JSON::ParserError => e
            raise InvalidResponseError, e.message
        end
      elsif data.class == Hash
          @payload = data
      else
          raise ArgumentError, "You must pass in either a url(String) or an entity(Hash) to SirenClient::Entity.new"
      end
      parse_data
    end

    #### Enumerable support

    # Returns the *i*th entity in this resource.
    # Returns nil on failure.
    def [](i)
      @entities[i] rescue nil
    end

    # Iterates over the entities in this resource.
    # Returns nil on failure.
    def each(&block)
      @entities.each(&block) rescue nil
    end
    
    def method_missing(method, *args)
      method_str = method.to_s
      return @entities.length if method_str == 'length'
      # Does it match a property, if so return the property value.
      @properties.each do |key, prop|
        return prop if method_str == key
      end
      # Does it match a link, if so traverse it and return the entity.
      @links.each do |key, link|
        return self.class.new(link.href) if method_str == key
      end
      # Does it match an action, if so return the action.
      @actions.each do |key, action|
        return action if method_str == key
      end
      raise NoMethodError, 'The method does not match a property, action, or link on SirenClient::Entity.'
    end

    private

    def parse_data
      return if @payload.nil?
      @classes    = @payload['class']      || []
      @properties = @payload['properties'] || { }
      @entities   = @payload['entities']   || []
      @entities.map! do |data|
        self.class.new(data)
      end
      @rels  = @payload['rel']   || []
      @links = @payload['links'] || []
      @links.map! do |data|
        Link.new(data)
      end
      # Convert links into a hash
      @links = @links.inject({}) do |hash, link|
        next unless link.rels.length > 0
        # Don't use a rel name if it's generic like 'collection'
        hash_rel = nil
        generic_rels = ['collection']
        link.rels.each do |rel|
          next if generic_rels.include?(rel)
          hash_rel = rel and break
        end
        # Ensure the rel name is a valid hash key
        hash[hash_rel.underscore] = link
        hash
      end
      @actions = @payload['actions'] || []
      @actions.map! do |data|
        Action.new(data)
      end
      # Convert actions into a hash
      @actions = @actions.inject({}) do |hash, action|
        next unless action.name
        hash[action.name.underscore] = action
        hash
      end
      @title = @payload['title'] || ''
      @href  = (@payload['href']  || @links['self'].href || '') rescue nil
      @type  = @payload['type']  || ''
    end
  end
end
