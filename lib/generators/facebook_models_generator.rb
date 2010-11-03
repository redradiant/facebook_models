require 'rails/generators'
require 'rails/generators/base'
require 'ruby-debug'
require 'pp'

lib = File.expand_path('../../', __FILE__)
puts lib
$LOAD_PATH << lib unless $LOAD_PATH.include? lib

require 'facebook_models'
require 'facebook_models/doc_scraper'

class FacebookModelsGenerator < Rails::Generators::Base
  desc "This generator will query the Facebook Graph API documentation and build a schema of its object space."
  argument :models, :type => :array, :default => [], :banner => "A list of Facebook models to generate or 'ALL' to generate all of them."

  source_root File.expand_path('../templates', __FILE__)

  class_option :include_collections,
               :type => :boolean,
               :aliases => '-c',
               :desc => "Include and try to specify collections in models.",
               :default => true

  class_option :namespace,
               :type => :string,
               :aliases => '-n',
               :desc => "The namespace to prefix local model class names with (i.e. Facebook)",
               :default => ''

  class_option :primary_key,
               :type => :string,
               :aliases => '-k',
               :desc => "The column to use as the primary key in the generated models.",
               :default => 'id'

  class_option :create_migration,
               :type => :boolean,
               :aliases => '-t',
               :desc => "Create a migration with the appropriate fields if the table does not exist.",
               :default => true

  class_option :force,
               :type => :boolean,
               :aliases => '-f',
               :desc => "Force overwriting of existing class and dropping/recreation of associated table.  Careful!",
               :default => false

  class_option :path,
               :type => :string,
               :aliases => '-p',
               :desc => "The directory in which to create model files (relative to app root).",
               :default => Rails.root

  

  def generate_facebook_models
    models.each do |model|
      ensure_facebook_model_exists!(model)
      newmodel = FacebookModels::Model.new(model, schema[model], opts)
      #######  THIS IS WHERE WE WILL DO THE REAL GENERATION!!!
    end
  end


  protected

  include FacebookModels::DocScraper

  def ensure_facebook_model_exists!(model)
    raise "Facebook model of type #{model} does not exist!" if (schema[model.to_s].blank? rescue true)
  end

  def opts
    @opts ||= ActiveSupport::OrderedHash.new.deep_merge(options).deep_symbolize_keys
  end

  # Actually create the model
  def create_model_file_for(model)
    #template 'cell.rb', File.join('app/cells', class_path, "#{file_name}_cell.rb")
  end

  def schema(force = false)
    @schema = nil if force == true
    @schema ||= scrape_schema!
    @schema = @schema.stringify_keys.to_hash.slice(*models)
  end

  def extract_class_mappings!
    if file_name =~ /^(add|remove)_.*_(?:to|from)_(.*)/
      @migration_action = $1
      @table_name       = $2.pluralize
    end
  end
  

end
