# Rails::Swagger

Creates mountable Rails engines to serve the actual APIs defined in your Swagger spec files.

**What it does:**
 - [x] Automatically routes API endpoints based on your Swagger spec files
 - [ ] Automatically validates request parameters using JSON Schema before they are passed to controller actions
 - [x] Allows multiple spec files to be mounted
 - [x] Supports JSON spec files
 - [ ] Supports YAML spec files

## Installation

Add this line to your application's Gemfile then execute `bundle install`:

```ruby
gem 'rails-swagger'
```

## Usage

Simply mount your swagger files within your routing tree...

```ruby
# config/routes.rb

Rails.application.routes.draw do

  # Mounts on /v1 with a controller prefix of Api::V1::
  mount Rails::Swagger::Engine("Api::V1", "path/to/swagger_api_v1.json"), at: :v1, as: :v1

  # Mounts on /pet_store with a controller prefix of PetStore::
  mount Rails::Swagger::Engine("PetStore", "path/to/petstore.yaml"), at: :pet_store, as: :pet_store

end
```

Verify that your routes are loaded...

```shell
$ rake routes
```

And ensure that your controllers include the module that `rails-swagger` generates for you:

```ruby
class PetStore::PetsController < ApplicationController
  include PetStore::SwaggerController
end

class Api::V1::Nested::ExampleController < ApplicationController
  include Api::V1::SwaggerController
end
```

### Technical Details

#### Syntactic Sugar

Unless you've used something like [Sequel](https://github.com/jeremyevans/sequel) before, the syntactic sugar of how engines are defined may look strange at first glance.

Under the hood, those engines are actually created via a *method call* that returns a newly-created subclass. `Rails::Swagger:Engine` is not a class, but simply a method that returns one.

#### Rails::Swagger#Engine

A method that takes two arguments. The first represents the namespace that will be used to prefix everything related to this engine. This includes any controllers used by the engine, the `SwaggerController` helper module, and the engine itself.

The second argument is the path to the swagger spec file to route from. This gem utilizes RESTful routing conventions and assumes your controllers / actions will be named accordingly.

#### _YourModulePrefix_#SwaggerController

A module that is defined when `Rails::Swagger#Engine` is invoked. It should be included in every controller that handles routes managed by `rails-swagger`. Please note that an instance of this module is created for every swagger spec file that is mounted.

## Contributing

Pull requests are welcome!
