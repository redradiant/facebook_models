module FacebookModels
  
  class Model

    attr_accessor :fb_type, :fb_data, :options

    def initialize(fb_type, fb_data, options = {})
      @fb_data = ActiveSupport::OrderedOptions.new.merge(fb_data.symbolize_keys)
      raise "No Facebook model name provided!" unless @fb_type = fb_type
      @options = (ActiveSupport::OrderedOptions.new.merge(options.symbolize_keys) rescue nil)
    end

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

    def local_path
      options.path.blank? ? File.expand_path('app/models', Rails.root) : File.expand_path(sane_relative_path(options.path), Rails.root)
    end

    def namespace
      options.namespace.blank? ? '' : "#{options.namespace rescue ''}".classify.gsub(/:+$/, '') + '::'
    end

    # Guess the name of a local class given a Facebook class name
    def local_class_name
      ("#{namespace}#{options[:fb_class].to_s.classify}" rescue fb_class).to_s
    end
    
    def local_class
      local_class_name.constantize
    end

    def fb_class_name
      options.fb_class.to_s
    end
    
    def fb_class
      fb_class_name.constantize
    end

  end # Guesser
end
