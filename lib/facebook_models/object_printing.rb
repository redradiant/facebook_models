require 'pp'

class Object

  cattr_accessor :ap_options
  @@ap_options = { :multiline => true,
                   :plain  => true,
                   :indent => 8 }

  def self.define_printer!
    begin
      require 'ap' or raise
      define_method(:to_code_string) do
        multiline = (self.flatten.size > 8 rescue false) ? true : false
        ap(self, self.class.ap_options.merge(:multiline => multiline))
      end
    rescue Exception => e
      require 'pp'
      define_method(:to_code_string) { pretty_inspect.to_s }
    end
  end
  
  def to_code(indent = 8)
    self.class.define_printer! unless respond_to?(:to_code_string)
    to_code_string rescue self.pretty_inspect
  end
end


class Array
  @@ap_options = { :multiline => false,
                   :plain  => true,
                   :indent => 8 }

end
