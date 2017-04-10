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
			def path_mode
				mode = :resource
				mode = :namespace if @routes.count == 0
				mode = :action if @subpaths.count == 0 && @prefix.count > 1
				mode
			end

			# Returns the mode used for actions in this router
			def action_mode
				if /^:/ === @prefix[-2]
					:member
				elsif /^:/ === @prefix[-1]
					:param
				else
					:collection
				end
			end

			# Determines the action for a specific route
			def action_for route
				raise "Argument must be a Route" unless Route === route
				action = @prefix[-1]
				action = VARIATE_ROUTES[route[:method]] if self.action_mode == :param
				action = RESOURCE_ROUTES[route[:method]] if self.path_mode == :resource && self.action_mode == :collection
				action
			end

			# Draws the routes for this router
			def draw map
				path = @prefix.join "/"
				endpoint = @prefix.last
				indent = "\t" * @prefix.count
				case self.path_mode
				when :resource
					puts "#{indent}resources :#{endpoint}"
					map.resources endpoint.to_sym, only: [] do
						draw_actions! map
						draw_subroutes! map
					end
				when :namespace
					if path.blank?
						draw_subroutes! map
					else
						puts "#{indent}namespace :#{endpoint}"
						map.namespace endpoint do
							draw_subroutes! map
						end
					end
				when :action
					draw_actions! map
				end

			end

			def routing_tree

				puts self.path + " - #{self.path_mode}"
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

		protected

			def draw_actions! map
				indent = "\t" * @prefix.count
				endpoint = @prefix.last
				@routes.each do |route|

					params = Hash.new
					params[:via] = route[:method]
					params[:on] = self.action_mode unless self.action_mode == :param
					params[:controller] = :foobar
					params[:action] = self.action_for route

					if Symbol === params[:action]
						params.delete :on
						puts "#{indent}match #{params}.inspect"
						map.match params
					else
						puts "#{indent}match #{endpoint}, #{params}.inspect"
						map.match endpoint, params
					end
				end
			end

			def draw_subroutes! map
				@subpaths.values.each do |subpath|
					subpath.draw map
				end
			end

		end

	end
end
