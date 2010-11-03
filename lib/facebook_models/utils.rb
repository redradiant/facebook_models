module FacebookModels
  module Utils

    def sanitize_filename(filename)
      returning filename.strip do |name|
       # NOTE: File.basename doesn't work right with Windows paths on Unix
       # get only the filename, not the whole path
       name.gsub! /^.*(\\|\/)/, ''

       # Finally, replace all non alphanumeric, underscore or periods with underscore
       #            name.gsub! /[^\w\.\-]/, '_'
       #            Basically strip out the non-ascii alphabets too and replace with x. You don't want all _ :)
        name.gsub!(/[^0-9A-Za-z.\-]/, 'x')
      end
    end

    def sanitized_expanded_path(path)
      raise "Rails not defined!" unless defined? Rails
      File.expand_path(sanitize_filename(path).gsub(/^\/*/, '').gsub(/\.\./, ''), Rails.root)
    end
    
  end
end
