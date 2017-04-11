module Rails
	module Swagger

		ALLOWED_FORMATS = [".json"].freeze

		class Engine < Rails::Engine
			isolate_namespace Rails::Swagger
		end

		# Creates a new engine using the provided swagger file
		def self.Engine base_module, file

			# Convert to a constant if a string was passed
			base_module = Object.const_get base_module if String === base_module

			# Sanity check
			ext = File.extname(file)
			unless ALLOWED_FORMATS.include? ext
				raise "Swagger files must end with #{ALLOWED_FORMATS.join(' or ')}. File given: #{file}"
			end

			# Read the file
			contents = File.read file

			# Parse the swagger document
			document = nil
			if ext == ".json"

				require 'json'
				begin
					document = JSON.parse contents
				rescue JSON::ParserError
					raise $!, "Problem parsing swagger file \"#{file}\": #{$!.message.lines.first.strip}", $@
				end

			end

			# Verify the supported swagger versions
			unless document["swagger"] == "2.0"
				raise "Unsupported swagger version: #{document["swagger"]}. Rails::Swagger supports only version 2.0"
			end

			# Build a routing tree
			router = Router.new
			endpoints = []
			document["paths"].each do |url, actions|
				actions.each do |verb, schema|
					route = Endpoint.new(verb.downcase.to_sym, url, schema)
					endpoints << route
					router << route
				end
			end

			# Instantiate a new rails engine
			engine = Class.new Engine do

				@router = router
				@endpoints = Hash.new

				class << self
					def router
						@router
					end
					def endpoints
						@endpoints
					end
				end

				# Draw the routes
				self.routes.draw do
					scope module: base_module.name.underscore, format: false do
						router.draw self
					end
				end

			end
			base_module.const_set :Engine, engine

			# Map the routes
			endpoints.each do |route|

				# Mock a request using this route's URL
				url = route.path
				req = ::ActionDispatch::Request.new ::Rack::MockRequest.env_for(::ActionDispatch::Journey::Router::Utils.normalize_path(url), method: route[:method].upcase)

				# Store the route where it lands
				mapped = engine.routes.router.recognize(req){}.first[1]
				key = "#{mapped[:controller]}##{mapped[:action]}"
				engine.endpoints[key] = route

			end
			engine.endpoints.freeze

			# Define a controller method
			def base_module.Controller base_class
				base = self
				Class.new base_class do
					include Controller
					define_method :rails_swagger_engine { base.const_get :Engine }
				end
			end

			# Return it
			base_module.const_get :Engine

		end

	end
end
