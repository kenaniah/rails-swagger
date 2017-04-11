module Rails
	module Swagger
		module Controller
			def self.included base

				base.class_eval do
					before_action :validate_swagger_params
				end

				def validate_swagger_params
					endpoint = rails_swagger_engine.endpoints["#{params[:controller]}##{params[:action]}"]
					puts endpoint.inspect
				end

			end
		end
	end
end
