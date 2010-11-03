require 'mechanize'

module FacebookModels
  class Client

    def initialize(email = nil, pass = nil)
      @email, @pass = email, pass
      @agent = Mechanize.new
      @agent.user_agent_alias = 'Windows IE 7'
      @logged_in = false
      login if (active? && can_login?)
      @agent
    end

    def active?
      (!@agent.blank? && @agent.respond_to?(:get)) rescue false
    end

    def can_login?
      (!@email.blank? && !@pass.blank? && !@agent.blank?)
    end

    def logged_in?
      @logged_in
    end

    def login!
      raise "Unable to login successfully!" unless login
      @agent
    end

    def login
      f = @agent.get("http://www.facebook.com/login.php").forms.first
      f.email = @email
      f.pass = @pass
      f.submit
      f.submit rescue nil
      @logged_in = active? && ((@agent.get("http://www.facebook.com/home.php").body.match(/News\s+Feed/i) ? true : false) rescue false)
    end

    # Delegate everything to the agent.
    def method_missing(method, *args, &block)
      active? ? @agent.send(method, *args, &block) : super(method, *args, &block)
    end

  end
end
