# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "rails-swagger"
  s.version       = "0.4.0"
  s.authors       = ["Kenaniah Cerny"]
  s.email         = ["kenaniah@gmail.com"]

  s.summary       = "Turns Swagger API schemas into mountable Rails engines"
  s.homepage      = "https://github.com/kenaniah/rails-swagger"

  s.files         = `git ls-files -z`.split("\x0").select{ |f| f.match(/lib\//) }
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler"
  s.add_development_dependency "rails", "~>5.1"
  s.add_development_dependency "rake"
  s.add_development_dependency "sqlite3"
end
