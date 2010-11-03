class <%= class_name %> < ActiveRecord::Base
  include FacebookModels::Extensions
  <%= "include Facebook::Agent" if has_agent %>
  
  define_attr_method :fb_type, "<%= model.fb_type %>"
  
  # All of the Facebook properties
  attr_accessor *<%= model.property_names.to_code %>
  attribute_method_suffix '_updatefb!'
  
  # All of the Facebook connections
  attr_accessor *<%= model.connection_names.to_code %>
  
  @@fb_data = <%= model.fb_data.to_code %>
  
  # Call to define_attribute_methods must appear after the
  # attribute_method_prefix, attribute_method_suffix or
  # attribute_method_affix declares.
  define_attribute_methods <%= model.all_field_names.to_code %>


  private


  <%- properties.each do |p| %>
  def <%= p %>
    fb.data[:<%= p %>]
  end
  <%- end %>

  <%- connections.each do |c| %>
  def <%= c %>
    fb.on("<%= c %>")
  end
  
  def <%= c %>!
    fb.on("<%= c %>").data
  end
  <%- end %>

end
