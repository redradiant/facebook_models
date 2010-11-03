require 'facebook/request'

module FacebookModels

  module Extensions
    included do
      require 'facebook/request'
      base.class_eval do
        include ActiveModel::AttributeMethods
        cattr_accessor :fb_type
        cattr_accessor :fb_data
      end
      
      raise "This can only be mixed into a class that defines a fb_agent method!" unless base.instance_methods.include?("fb_id")
      raise "Must implement the Facebook interface." unless base.respond_to?(:fb_data)
      raise "Must implement the Facebook interface." unless base.respond_to?(:fb_type)
    end
    
    module ClassMethods
      def doc_url
        "#{Rails.configuration.facebook_models.api_docs_url}/#{fb_type.to_s.downcase}" rescue nil
      end

      def fb_metadata
        return fb_data unless !@agent.blank? && @agent.logged_in?
        FacebookModels::Config.agent
      end

      def connections
        fb_data.connections
      end

      def properties 
        fb_data.properties
      end
      
      def all_fields
        (properties | connections)
      end

      def property_names
        properties.map {|p| p.name.to_s }.map(&:to_sym)
      end

      def connection_names
        connections.map {|p| p.name.to_s }.map(&:to_sym)
      end

      def all_field_names
        all_fields.map {|p| p.name.to_s }.map(&:to_sym)
      end
    end

    module InstanceMethods
      def access_token?
        self.respond_to?(:facebook_token) && !self.facebook_token.blank?
      end

      # TODO: cache this?  Or is cloning enough?
      def fb(connection = nil)
        r = FacebookModels::Request.new.owner(self).with_agent(fb_agent)
        r.connection(connection) unless connection.blank?
        (access_token? ? r.auth(facebook_token) : r).dup
      end

      def fb_me
        @me ||= fb.data
      end

    end
  end
end
