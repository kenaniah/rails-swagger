module Rails
	module Swagger

		Route = Struct.new(:method, :path, :schema)

		RESOURCE_ROUTES = {
			get: :index,
			post: :create
		}.freeze
		VARIATE_ROUTES = {
			get: :show,
			patch: :update,
			put: :update,
			delete: :destroy
		}.freeze

		class Router

			def initialize prefix = []
				@prefix = prefix
				@routes = []
				@subpaths = Hash.new do |hash, k|
					hash[k] = Router.new(@prefix + [k])
				end
			end

			# Adds an individual route to the routing tree
			def << route
				raise "Argument must be a Route" unless Route === route

				# Split off the first element of the path
				base, *subpath = route[:path].split '/'
				if subpath.count == 0
					route[:path] = ""
					@routes << route
				else
					route[:path] = subpath.join '/'
					self[subpath[0]] << route
				end
			end

			# Returns a specific branch of the routing tree
			def [] path
				@subpaths[path]
			end

			def type

				mode = :resource
				mode = :namespace if @routes.count == 0
				mode = :action if @subpaths.count == 0

				path = "/" + @prefix.join("/")
				puts path + " - #{mode}"
				@routes.each do |route|
					context = if /^:/ === @prefix[-2]
						:member
					elsif /^:/ === @prefix[-1]
						:variate
					else
						:static
					end
					action = @prefix[-1]
					action = VARIATE_ROUTES[route[:method]] if context == :variate
					action = RESOURCE_ROUTES[route[:method]] if mode == :resource && context == :static
					puts "\t#{route[:method].to_s.upcase} to ##{action} (#{context})"
				end
				@subpaths.each do |k, subpath| subpath.type end

			end

			# Outputs the routing tree in text format
			def to_s

				output = ""

				path = "/" + @prefix.join('/')
				@routes.each do |route|
					output += "#{route[:method].to_s.upcase} #{path}\n"
				end
				@subpaths.each do |k, subpath|
					output += subpath.to_s
				end

				output

			end

		end

	end
end
