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

And ensure that your controllers extend from one that `rails-swagger` generates for you:

```ruby
class PetStore::PetsController < PetStore::Controller ApplicationController
  # Inherits from PetStore::Controller < ApplicationController
end

class OtherController < ApplicationController; end

class Api::V1::ExampleController < Api::V1::Controller OtherController
  # Inherits from Api::V1::Controller < OtherController < ApplicationController
end
```

### Technical Details

#### Syntactic Sugar

Unless you've used something like [Sequel](https://github.com/jeremyevans/sequel) before, the syntactic sugar of how controllers are defined may look strange at first glance.

Under the hood, those controllers are extending from an anonymous class that is created and returned from a *method call*. `API::V1::Controller` is not a class, but simply a method that returns one. The `IntermediateController` is the first positional argument.

This is accomplished by defining a method named `Controller` directly on the module object provided as the first argument to `Rails::Swagger::Engine`.

#### Rails::Swagger#Engine

A method that takes two arguments. The first represents the namespace that will be used to prefix everything related to this engine. This includes any controllers used by the engine, the `#Controller` helper method, and the engine itself.

The second argument is the path to the swagger spec file to route from. This gem utilizes RESTful routing conventions and assumes your controllers / actions will be named accordingly.

#### _YourModulePrefix_#Controller

This is a method that is defined when `Rails::Swagger#Engine` is invoked. Pass it the class that you would like your controller to transparently inherit from, and it will generate an intermediate class that includes all of the `rails-swagger` functionality.

Please note that these intermediate classes are tailored to each swagger spec file that is mounted. Without this, `rails-swagger` can not automatically validate request parameters.

## Contributing

Pull requests are welcome!
