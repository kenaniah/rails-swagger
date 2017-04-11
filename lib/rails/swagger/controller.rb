module Rails
	module Swagger
		module Controller
			def self.included base

				base.class_eval do
					before_action :validate_swagger_params
				end

				def validate_swagger_params
					swagger = rails_swagger_engine.definitions["#{params[:controller]}##{params[:action]}"]
					puts swagger.inspect
				end

			end
		end
	end
end
