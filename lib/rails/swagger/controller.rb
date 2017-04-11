module Rails
	module Swagger
		module Controller

			# Injects swagger-related code into the controller when included
			def self.included base

				# Add controller hooks
				base.class_eval do
					before_action :validate_swagger_params
				end

				# Returns the swagger spec definition for the endpoint serving
				# the current request.
				def swagger_endpoint
					key = "#{params[:controller]}##{params[:action]}"
					endpoint = rails_swagger_engine.endpoints[key]
				end

				# Validates request parameters against the Swagger API spec
				# associated with this controller.
				def validate_swagger_params
					puts swagger_endpoint.inspect.white
				end

			end

		end
	end
end
