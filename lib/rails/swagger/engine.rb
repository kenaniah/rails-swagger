module Rails

  module Swagger

    # Defines the Swagger spec file formats that are parsable by this gem.
    # Currently only the JSON format is supported.
    ALLOWED_FORMATS = [".json"].freeze

    # Defines a base class from which Swagger API engines can be created.
    # Uses namespace isolation to ensure routes don't conflict with any
    # pre-existing routes from the main rails application.
    class Engine < Rails::Engine
      isolate_namespace Rails::Swagger
    end

    # Helper method to create a new engine based on a module namespace
    # prefix and Swagger spec file. The engine ceated will be a subclass of
    # Rails::Swagger::Engine, which itself inherits from Rails::Engine.
    def self.Engine base_module, file

      # Convert the module prefix into a constant if passed in as a string
      base_module = Object.const_get base_module if String === base_module

      # Ensure the Swagger spec file is in an acceptable format
      ext = File.extname(file)
      unless ALLOWED_FORMATS.include? ext
        raise "Swagger files must end with #{ALLOWED_FORMATS.join(' or ')}. File given: #{file}"
      end

      # Attempt to read and parse the Swagger spec file
      document = File.read file
      case File.extname file
      when ".json"
        begin
          require 'json'
          document = JSON.parse document
        rescue JSON::ParserError
          raise $!, "Problem parsing swagger spec file \"#{file}\": #{$!.message.lines.first.strip}", $@
        end
      else
        raise "Swagger files must end with #{ALLOWED_FORMATS.join(' or ')}. File given: #{file}"
      end

      # Verify that the swagger version is supported
      unless document["swagger"] == "2.0"
        raise "Unsupported swagger version: #{document["swagger"]}. #{self} supports only version 2.0"
      end

      # Builds a routing tree based on the swagger spec file.
      # We'll add each endpoint to the routing tree and additionally
      # store it in an array to be used below.
      router = Router.new
      endpoints = []
      document["paths"].each do |url, actions|
        actions.each do |verb, definition|
          route = Endpoint.new(verb.downcase.to_sym, url, definition)
          router << route
          endpoints << route
        end
      end

      # Creates the engine that will be used to actually route the
      # contents of the swagger spec file. The engine will eventually be
      # attached to the base module (argument to this current method).
      #
      # Exposes `::router` and `::endpoints` methods to allow other parts
      # of the code to tie requests back to their spec file definitions.
      engine = Class.new Engine do

        @router = router
        @endpoints = Hash.new
        @schema = document

        class << self
          def router
            @router
          end
          def endpoints
            @endpoints
          end
          def schema
            @schema
          end
        end

        # Rack app for serving the original swagger file
        # swagger_app = Class.new do
        #   def inspect
        #     "Rails::Swagger::Engine"
        #   end
        #   define_method :call do |env|
        #     [
        #       200,
        #       {"Content-Type" => "application/json"},
        #       [engine.schema.to_json]
        #     ]
        #   end
        # end

        # Adds routes to the engine by passing the Mapper to the top
        # of the routing tree. `self` inside the block refers to an
        # instance of `ActionDispatch::Routing::Mapper`.
        self.routes.draw do
          scope module: base_module.name.underscore, format: false do
            # get "swagger.json", to: swagger_app.new
            router.draw self
          end
        end

      end

      # Assign the engine as a class on the base module
      base_module.const_set :Engine, engine

      # Creates a hash that maps routes back to their swagger spec file
      # equivalents. This is accomplished by mocking a request for each
      # swagger spec file endpoint and determining which controller and
      # action the request is routed to. Swagger spec file definitions
      # are then attached to that controller/action pair.
      endpoints.each do |route|

        # Mocks a request using the route's URL
        url = ::ActionDispatch::Journey::Router::Utils.normalize_path route.path
        env = ::Rack::MockRequest.env_for url, method: route[:method].upcase
        req = ::ActionDispatch::Request.new env

        # Maps the swagger spec endpoint to the destination controller
        # action by routing the request.
        mapped = engine.routes.router.recognize(req){}.first[1]
        key = "#{mapped[:controller]}##{mapped[:action]}"
        engine.endpoints[key] = route

      end
      engine.endpoints.freeze

      # Defines a helper module on the base module that can be used to
      # properly generate swagger-aware controllers. Any controllers
      # referenced from a swagger spec file should include this module.
      mod = Module.new do
        @base = base_module
        def self.included controller
          base_module = @base
          controller.include Controller
          define_method :swagger_engine do
            base_module.const_get :Engine
          end
        end
      end
      base_module.const_set :SwaggerController, mod

      # Returns the new engine
      base_module.const_get :Engine

    end

  end

end
