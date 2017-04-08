module Rails
	module Swagger

		Route = Struct.new(:method, :path, :schema)

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
