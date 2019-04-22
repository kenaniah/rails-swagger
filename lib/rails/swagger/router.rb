module Rails

  module Swagger

    # Internally represents individual routes
    Endpoint = Struct.new(:method, :url, :definition, :_path) do
      def initialize *opts
        super
        self[:_path] = self.path
      end
      # Translates path params from {bracket} syntax to :symbol syntax
      def path
        self[:url].gsub(/\{([^}]+)\}/, ':\\1')
      end
    end

    # Defines RESTful routing conventions
    RESOURCE_ROUTES = {
      get: :index,
      post: :create
    }.freeze
    PARAM_ROUTES = {
      get: :show,
      patch: :update,
      put: :update,
      delete: :destroy
    }.freeze

    class Router

      attr_accessor :endpoints

      def initialize prefix = [], parent = nil
        @parent = parent
        @prefix = prefix.freeze
        @endpoints = []
        @subroutes = Hash.new do |hash, k|
          hash[k] = Router.new(@prefix + [k], self)
        end
      end

      # Adds an individual endpoint to the routing tree
      def << route
        raise "Argument must be an Endpoint" unless Endpoint === route
        _base, *subroute = route[:_path].split '/' # Split out first element
        if subroute.count == 0
          route[:_path] = ""
          @endpoints << route
        else
          route[:_path] = subroute.join '/'
          self[subroute[0]] << route
        end
      end

      # Returns a specific branch of the routing tree
      def [] path
        @subroutes[path]
      end

      # Returns the routing path
      def path
        "/" + @prefix.join("/")
      end

      # Returns the mode used for collecting routes
      def route_mode
        mode = :resource
        mode = :namespace if @endpoints.count == 0
        mode = :action if @subroutes.count == 0 && @parent && @parent.route_mode == :resource
        mode = :param if /^:/ === @prefix.last
        mode
      end

      # Returns the mode used for actions in this router
      def action_mode
        if /^:/ === @prefix[-1]
          :param
        else
          :collection
        end
      end

      # Determines the action for a specific route
      def action_for route
        raise "Argument must be an Endpoint" unless Endpoint === route
        action = @prefix[-1]
        action = PARAM_ROUTES[route[:method]] if self.action_mode == :param
        action = RESOURCE_ROUTES[route[:method]] if self.route_mode == :resource && self.action_mode == :collection
        action
      end

      # Draws the routes for this router
      def draw map

        case self.route_mode
        when :resource

          # Find collection-level resource actions
          actions = @endpoints.map{ |r| self.action_for r }.select{ |a| Symbol === a }

          # Find parameter-level resource actions
          @subroutes.select{ |k, _| /^:/ === k }.values.each do |subroute|
            actions += subroute.endpoints.map{ |r| subroute.action_for r }.select{ |a| Symbol === a }
          end

          # Draw a resource
          map.resources @prefix.last.to_sym, only: actions do
            draw_actions! map
            draw_subroutes! map
          end

        when :namespace

          # Draw a namespace (unless at the top)
          if @prefix.join("/").blank?
            draw_subroutes! map
          else
            map.namespace @prefix.last do
              draw_subroutes! map
            end
          end

        when :param

          # Draw subroutes directly
          draw_subroutes! map
          draw_actions! map

        when :action

          # Draw actions directly
          draw_actions! map

        end

      end

      # Returns the routing tree in text format
      def to_s

        output = ""

        path = "/" + @prefix.join('/')
        @endpoints.each do |route|
          output += "#{route[:method].to_s.upcase} #{path}\n"
        end
        @subroutes.each do |k, subroute|
          output += subroute.to_s
        end

        output

      end

      # Outputs a visual representation of the routing tree
      def _debug_routing_tree

        puts self.path + " - #{self.route_mode}"
        @endpoints.each do |route|
          puts "\t#{route[:method].to_s.upcase} to ##{self.action_for route} (#{self.action_mode})"
        end
        @subroutes.each do |k, subroute| subroute._debug_routing_tree end

      end

    protected

      def draw_actions! map

        @endpoints.each do |route|

          # Params hash for the route to be added
          params = Hash.new
          params[:via] = route[:method]
          params[:on] = self.action_mode unless self.action_mode == :param
          params[:action] = self.action_for route

          # These are handled in the resource
          next if Symbol === params[:action]

          # Add this individual route
          map.match @prefix.last, params

        end

      end

      def draw_subroutes! map
        @subroutes.values.each { |r| r.draw map }
      end

    end

  end

end
