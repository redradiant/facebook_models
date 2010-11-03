require 'active_support' unless defined? ActiveSupport
require 'rails' unless defined? Rails

$LOAD_PATH << File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.uniq!

require 'facebook_models'
