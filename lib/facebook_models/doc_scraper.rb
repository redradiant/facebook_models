require 'nokogiri'
require 'text/highlight'
require 'facebook_models/client'
require 'ruby-debug'

module FacebookModels
  module DocScraper

    attr_writer :agent

    def agent
      return @agent if (!@agent.blank? && @agent.respond_to?(:get) rescue false)
      begin
        raise "This part isn't working yet and may not be needed."
        raise "No test Facebook user given." if (Rails.configuration.fbgraph.test_user.blank? rescue true)
        @agent = FacebookModels::Client.new(Rails.configuration.fbgraph.test_user, Rails.configuration.fbgraph.test_pass)
        @agent.login!
      rescue
        puts "Reverting to anonymous agent.".red
        @agent = nil
      end
      @agent ||= Mechanize.new
      @agent.user_agent_alias = 'Windows IE 7'
      @agent
    end

    def scrape_schema!
      doc_url = Rails.configuration.facebook_models.api_docs_url
      String.highlighter = Text::ANSIHighlighter.new

      puts "\n########################################################################".cyan
      puts "# Scraping Facebook object space schema from API docs...".cyan
      puts "# URL: #{doc_url}".cyan
      puts "#########################################################################\n\n".cyan

      classes = {}
      doc = agent.get(doc_url).parser
      doc.css('div.page').each do |n|
        type = (n/'a')[0].content
        classes[type] = Hash.new
        classes[type][:url] = "#{doc_url}#{(n/'a')[0].attribute("href")}"
        puts "Discovered Facebook object type #{type.magenta}"
      end

      puts "\n\n"
      
      #perm = agent.get("http://developers.facebook.com/docs/authentication/permissions").parser
      #perms = (perm/"code").select {|p| p.content.match(/^[a-z_]+$/) }

      classes.each_pair do |type, opts|
        type = type.to_s
        opts.symbolize_keys!
        url = opts[:url]
        #puts "\n------------------------------------------------------------------------"
        puts "- Attempting to fetch properties for type: #{type.green}"
        puts "- URL: #{url.yellow}"
        #puts "-------------------------------------------------------------------------"

        begin
          raise "Facebook agent not active." unless agent.logged_in?
          doc_page = agent.get(url)
          api_url = doc_page.links_with(:href => /access_token/).first.href + "&metadata=1"
          json = agent.get(api_url)
          details = ActiveSupport::JSON.decode(json)
          raise "Invalid JSON received from #{api_url}" unless details.has_key?("metadata")
          details["metadata"]["fields"].each do |field|
            classes[type][:properties].push(field.symbolize_keys)
          end
          details["metadata"]["connections"].each_pair do |connection, link|
            val = { :name => connection.to_sym }
            if (m = perms.grep(/^([^\_]_#{connection})$/) rescue false)
              val.merge!(:required_permissions => m)
            end
            classes[type][:connections].push(val)
          end          
        rescue
          puts "Scraping from HTML".red

          doc = agent.get(url).parser
          #  link = ((doc/'h2').detect {|h| h.content == "Example" }.next.children.first.attribute("href").value + "?metadata=1&access_token=#{TOKEN}" rescue nil)

          # Parse the HTML page
          (doc/"table").each do |t|
            key = t.previous.content.downcase.to_sym rescue nil
            next unless [ :properties, :connections ].include?(key)

            classes[type][key] = []

            elements = (t/'tr').collect do |r|
              attr = ((r/'td').first.content).gsub(/\s/, '').to_sym
              perms = ((r/'td').last/'code').collect { |p| p.content.to_sym } rescue nil
              description = ((r/'td').last.content).gsub(/\n/, '')
              classes[type][key].push({
                :name => attr,
                :description => description,
                :required_permissions => perms
                })
                
              # See if this connection is to real Facebook objects...
              if type == :connections
                fb_class = attr.to_s.classify
                if (Rails.configuration.facebook_models.all_fb_models.include?(fb_class) rescue false)
                  classes[type][key].merge!(:fb_type => fb_class)
                end
              end
              
            end # rows
          end # tables        
        end # end begin block

        puts "  + Properties  : #{classes[type][:properties].map {|i| i[:name] }.join(', ')}" unless classes[type][:properties].blank?
        puts "  + Connections : #{classes[type][:connections].map {|i| i.has_key?(:fb_type) ? "#{i[:name]}[fb: #{i[:fb_type]}]" : i[:name] }.join(', ')}" unless classes[type][:connections].blank?
        puts "\n"
      end # object class loop

      classes
    rescue Exception => e
      raise
      #raise RuntimeError, "Unable to retrieve Facebook API schema: #{e.message}"
    end

  end #module
end # module
