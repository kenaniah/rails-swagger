module Rails
	module Swagger

		ALLOWED_FORMATS = [".json"].freeze

		class Engine < Rails::Engine
			isolate_namespace Rails::Swagger
		end

		# Creates a new engine using the provided swagger file
		def self.Engine file

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

			document

			# Instantiate a new rails engine
			engine = Class.new Engine do

				self.routes.draw do

					document["paths"].each do |url, actions|
						actions.each do |verb, definition|
							url = url.gsub /\{(.+)\}/ do |m|
								# convert camelCase to underscores
								":" + $1.
									gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
									gsub(/([a-z\d])([A-Z])/,'\1_\2').
									downcase
							end
							puts "#{verb.upcase} #{url}".cyan
							#self.send(verb, url)
						end
					end

				end

			end

			# Return it
			engine

		end

	end
end
