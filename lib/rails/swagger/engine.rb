module Rails
	module Swagger
		class Engine < Rails::Engine
			isolate_namespace Rails::Swagger
		end
	end
end
