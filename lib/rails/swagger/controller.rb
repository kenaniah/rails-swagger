module Rails

  module Swagger

    module Controller

      # METHODS_WITH_BODIES = [
      #   :post,
      #   :patch,
      #   :put
      # ].freeze

      # Injects swagger-related code into the controller when included
      def self.included base

        # Add controller hooks
        # base.class_eval do
        #   before_action :swagger_validate_params
        # end

        # Returns the swagger spec definition for the endpoint serving
        # the current request.
        def swagger_endpoint
          key = "#{params[:controller]}##{params[:action]}"
          swagger_engine.endpoints[key]
        end

        # Validates request parameters against the Swagger API spec
        # associated with this controller.
        # def swagger_validate_params
        #   if METHODS_WITH_BODIES.include? request.method_symbol
        #     body = request.POST
        #     # TODO: add validation here
        #   end
        # end

      end

    end

  end

end
