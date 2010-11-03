$LOAD_PATH << File.dirname(__FILE__) unless $LOAD_PATH.include? File.dirname(__FILE__)

require 'facebook_models/object_printing'
require 'facebook_models/doc_scraper'
require 'facebook_models/model'
require 'facebook_models/utils'
require 'facebook_models/client'

module FacebookModels

  class Config
    include ActiveSupport::Configurable #:nodoc
    include Singleton

    config_accessor :api_docs_url, :all_fb_models, :agent, :test_user, :test_pass

  end


  class Railtie < Rails::Railtie
    railtie_name :facebook_models
    config.facebook_models = ::FacebookModels::Config.instance
    config.facebook_models.api_docs_url = "http://developers.facebook.com/docs/reference/api/"
    config.facebook_models.all_fb_models = [
        "User", "Checkin", "Post", "Group", "Status message", "Link", "Album", "Video",
        "Application", "Page", "Insights", "Event", "Subscription", "Photo", "Note" ]

    user = config.facebook_models.test_user = Rails.configuration.fbgraph.test_user rescue nil
    pass = config.facebook_models.test_pass = Rails.configuration.fbgraph.test_pass rescue nil
    agent = FacebookModels::Client.new(user, pass) rescue nil
    config.facebook_models.agent = agent

    generators do
      require "generators/facebook_model_generator"
    end

    #config.generators do |g|
    #  g.template_engine :erb
    #end

  end
end

