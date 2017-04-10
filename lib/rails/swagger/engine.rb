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
			document["paths"].each do |url, actions|
				actions.each do |verb, definition|
					url = url.gsub /\{(.+)\}/, ':\\1'
					puts "#{verb.upcase} #{url}".cyan
					router << Route.new(verb.downcase.to_sym, url, definition)
				end
			end
			# puts router.routing_tree

			# Instantiate a new rails engine
			engine = Class.new Engine do

				@router = router
				class << self
					def router
						@router
					end
				end

				# Draw the routes
				self.routes.draw do
					router.draw self
				end

			end
			base_module.const_set :SwaggerEngine, engine

			# Return it
			base_module.const_get :SwaggerEngine

		end

	end
end
