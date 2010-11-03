module FacebookModels
  class Request
    require 'uri'

    attr_accessor :objects, :params, :connection

    def initialize(*args)
      self.with_agent(*args)
    end

    def self.for_owner(*args)
      me = new
      me.owner(*args)
    end

    def owner(owner)
      @owner = owner
      if (@owner.fb_agent rescue false)
        with_agent(@owner.fb_agent)
      end
      for_objects(owner.facebook_id) rescue nil
      self
    end
    
    def on_ids(*new_objects)
      @objects ||= Array.new
      @objects = @objects.concat(*new_objects).flatten.compact
      self
    end
    alias :for_objects :on_ids
    
    def connection(new_c)
      @connection = new_c
      self
    end
    alias :on :connection
    
    def with(new_params = {})
      @params.merge!(new_params)
      self
    end
    
    def token(token = nil)
      @token = token || @token || (@params.delete(:access_token) rescue nil) || (@owner.facebook_token rescue nil) || nil
      self
    end
    alias :auth :token
    
    def object_ids
      @objects = [@objects] unless @objects.kind_of?(Array)
      return ["me"] if @objects.blank?
      @objects.flatten.map { |o| o.respond_to?(:facebook_id) ? o.facebook_id.to_s : o.to_s }.compact
    end
    
    def with_agent(new_agent = nil)
      if (new_agent.respond_to?(:get) rescue false)
        @agent = new_agent
      end
      self
    end
    alias :using :with_agent

    def has_agent?
      !(@agent.blank? || !@agent.respond_to?(:get))
    end

    def agent
       @agent ||= @owner.fb_agent if (!@owner.blank? && @owner.respond_to?(:fb_agent))
       has_agent? ? @agent : nil
    end
    alias :client :agent

    def url
      @params[:access_token] = token
      path = if ((object_ids.length > 1) rescue false)
        build_graph_path(nil,nil, @params.merge!({:ids => object_ids.join(',')}))
      else
        path = build_graph_path(object_ids.first.to_s , @connection_type, @params)
      end
      @url = "https://graph.facebook.com/#{path}"
    end
    alias :to_s :url
    
    def data
      fetch! if @data.blank?
      @data
    end

    def fetch!
      raise "No agent!" if !has_agent?
      begin
        @json = agent.get(url)
        @data = ActiveSupport::JSON.decode(@json)
      rescue
        @data = nil
        raise "There was an error with the request!\n#{@json}"
      end
    end

    def method_missing(method, *args, &block)
      data(method, *args, &block)
    end

    private

    def parse_json(result, parsed)
      hash_class = (defined?(::Hashie::Mash) rescue false) ? ::Hashie::Mash : HashWithIndifferentAccess
      return parsed  ? hash_class.new(JSON.parse(result.body)) : result.body
    end

    def build_graph_path(objects, connection_type = nil , params = {})
      request = [objects , connection_type].compact.join('/')
      request += "?"+params.to_a.map{|p| p.join('=')}.join('&') unless params.empty?
      URI.encode(request)
    end

  end
end
