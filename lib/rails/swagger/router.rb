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
				base, *subpath = route[:path].split '/' # Split out first element
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

			# Returns the routing path
			def path
				"/" + @prefix.join("/")
			end

			# Returns the mode used for collecting routes
			def collection_mode
				mode = :resource
				mode = :namespace if @routes.count == 0
				mode = :action if @subpaths.count == 0
				mode
			end

			# Returns the mode used for actions in this router
			def action_mode
				if /^:/ === @prefix[-2]
					:member
				elsif /^:/ === @prefix[-1]
					:variate
				else
					:static
				end
			end

			# Determines the action for a specific route
			def action_for route
				raise "Argument must be a Route" unless Route === route
				action = @prefix[-1]
				action = VARIATE_ROUTES[route[:method]] if self.action_mode == :variate
				action = RESOURCE_ROUTES[route[:method]] if self.collection_mode == :resource && self.action_mode == :static
				action
			end

			def routing_tree

				puts self.path + " - #{self.collection_mode}"
				@routes.each do |route|
					puts "\t#{route[:method].to_s.upcase} to ##{self.action_for route} (#{self.action_mode})"
				end
				@subpaths.each do |k, subpath| subpath.routing_tree end

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
