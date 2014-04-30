# Warning
This gem is undergoing heavy development and is using [Semantic
Versioning](http://semver.org/), which means that **nothing in version 0.1.x is
stable**. Things are changing rapidly; the API will be stabilized in version
1.0.0. In the meantime, any feedback and testing is welcome.

# Cathode
[![Gem Version](https://badge.fury.io/rb/cathode.svg)](http://badge.fury.io/rb/cathode)
[![Build Status](https://travis-ci.org/mobyinc/Cathode.svg)](https://travis-ci.org/mobyinc/Cathode)
[![Documentation](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/gems/cathode/0.1.0/frames)
[![Coverage Status](https://coveralls.io/repos/mobyinc/Cathode/badge.png)](https://coveralls.io/r/mobyinc/Cathode)
[![Code Climate](https://codeclimate.com/github/mobyinc/Cathode.png)](https://codeclimate.com/github/mobyinc/Cathode)
[![Dependency Status](https://gemnasium.com/mobyinc/Cathode.svg)](https://gemnasium.com/mobyinc/Cathode)

Cathode is a gem for Rails projects that provides a DSL for generating dynamic
API boilerplate (created at runtime, no generated files) for resourceful
applications. It comes with default behavior for CRUD operations and support for
ActiveModel associations, allowing you to greatly reduce the amount of
boilerplate you write. Cathode also supports custom actions and token
authorization. It has first-class support for versioning, so that nothing in
your API exists outside the context of a version.

## Features
* Versioning of resources and actions
* Default behavior for CRUD operations
  * Listing resources, optionally paginated
  * Finding a single resource
  * Creating a new resource
  * Updating a resource
  * Deleting a resource
* Endpoints respond to JSON and output JSON
* Custom (non-resourceful) actions on versions and resources
* Nested resources
* Singular resources
* Strong parameters
* API tokens

## Roadmap
See [roadmap.md](https://github.com/mobyinc/Cathode/blob/master/roadmap.md).

## Documentation
The full documentation is [here](http://rubydoc.info/github/mobyinc/Cathode/master/frames).

## Getting Started
### Requirements

* Ruby >= 1.9.3
* Rails >= 4.0 (we hope to support Rails 3.2 in the future)
* ActiveRecord (more ORMs will be supported in the future)

### Supported Database Adapters
Cathode supports (and is tested against) the following adapters:

* SQLite3
* MySQL
* PostgreSQL

### Installation
Install the gem:

```bash
gem install cathode
```

Mount the engine in your `config/routes.rb` file:
```ruby
mount Cathode::Engine => '/api' # use a namespace of your choice
```

### Defining Your API
Cathode’s DSL provides an easy way to define your API’s versions and the
resources inside of them. Place your API files in `app/api` for Cathode to load
them automatically; alternatively, place them anywhere you wish and `require`
them manually. See [Files & Naming Conventions](#files_naming) for some different ideas for
organizing your files.

```ruby
Cathode::Base.define do
  # version 1.0.0 is implied if no version block is given
  resources :products, actions: [:index, :show, :search]

  version '1.0.1' do
    resources :sales, actions: [:index, :show]
  end
end
```

Contrary to Rails’s `routes.rb` file–in which the default actions are included
unless explicitly excluded–only actions that you specify are defined. Out of
the box, the actions available are: `:index, :show, :create, :update, :delete`.

In version 1, the following endpoints are created: `get api/products/`, `get
api/products/{id}`, and `get api/products/search`. By default, all products will
be returned in the `index` call, and no permissions will be enforced on the
`show` call. By default, the `search` call will take a `query` parameter and
search for it using the `Product.title` field.

In version 1.0.1, endpoints are added for the `sales` endpoint: `get api/sales/`
and `get api/sales/{id}`. Those endpoints are not accessible in version 1.
However, because versions cascade, the actions on the `products` resource are all
accessible in version 1.0.1.

## Versioning
Cathode has first-class support for API versioning and aims to make extending
versions and deprecating old functionality an easy process. You’re encouraged to
use [Semantic Versioning](http://semver.org/), and all Cathode version numbers
must be SemVer-compliant.

If you define resources without a version, Cathode assumes it’s version
`1.0.0` of your API. When you’re ready to introduce changes, you can
easily provision a new version:

```ruby
resources :products, actions: [:index, :show, :search]

version 1.1 do
  resources :sales, actions: [:index]
  # the products resource is inherited from version 1
end

version 2 do
  # the products resource is inherited from version 1.1, except we explicitly
  # remove the `search` action
  remove_action :products, :search
end
```

Versions inherit from their ancestors, so anything not explicitly changed in
version `2` will be carried over from version `1.1`, which in turn inherits from
version `1`.

In version `1.1`, we’ve added a new `sales` endpoint. This doesn’t introduce a
breaking change, as users of version `1.0` can still use it without knowing
about the `sales` endpoint.

However, in version `2` we *do* introduce a breaking change–namely, that
products can no longer be searched. Users of versions `1.x` of our API will
still be able to access the endpoint, but users of version `2` will not.

Usually, changes like these would require the addition of new route namespaces
and groups of controllers. With Cathode, these are all taken care of for you.

Note that, while these examples are using minor- and patch-level versions, you
are not required to do so. You can use only major versions (x.0.0), major and
minor versions (x.y.0), or all three (x.y.z).

## Attributes Block (Strong Parameters)
Using Cathode’s `attribute` method, you can pass a block to any action that will
be evaluated by Rails’s [Strong Parameters](https://github.com/rails/strong_parameters).
The request params are available in the block’s context, so you can use the
strong params API just as you would in a controller.

The `create` and `update` actions require an attributes block be present if
you’re using the default action behavior. If you call `attributes` at the
resource level, Cathode uses it for both the `create` and `update` actions. Call
it at the action level to limit the strong params to just that action.

```ruby
# use the same attribute whitelist for `create` and `update`
resources :products, actions: [:create, :update] do
  attributes do
    params.require(:product).permit(:title, :description, :cost)
  end
end

# use different attribute whitelists for `create` and `update`
resources :products do
  action :create do
    attributes do
      params.require(:product).permit(:title, :description, :cost)
    end
  end

  action :update do
    attributes do
      params.require(:product).permit(:description, :cost)
    end
  end
end

# use strong params on a custom action
resources :products do
  get :custom do
    attributes do
      params.require(:secret)
    end
  end
end
```

Requests that raise a params exception (e.g., `ActionController::ParameterMissing`)
respond with `400 Bad Request`.

## Serialization
Cathode doesn’t do any explicit serialization of resources when responding to
requests. However, it does use `render: json`, which will invoke [ActiveModel
serializers](https://github.com/rails-api/active_model_serializers) if you’ve
defined them.

## API Tokens
Cathode comes with a token manager for controlling access to your API. By
default, tokens aren’t required to access any APIs you define. To require tokens
to access an API, use the `require_tokens` method:

```ruby
Cathode::Base.define do
  require_tokens

  resources :products, actions: [:index]
end
```

Cathode doesn’t currently have a way to associate tokens with a particular user,
nor does it generate tokens automatically. Use Cathode’s `Token` model to generate
a new token:

```ruby
Cathode::Token.new
```

Rails’s [`authenticate_or_request_with_http_token`](http://apidock.com/rails/ActionController/HttpAuthentication/Token/ControllerMethods/authenticate_or_request_with_http_token) scheme is used to validate tokens, so API consumers
must pass a valid `Authorization` header in the following form:

```
Authorization: Token token={consumer’s token}
```

## CORS
Because Cathode is meant to be paired with a client-side Anode library,
cross-origin resource sharing (CORS) is enabled by adding
[Rack::Cors](https://github.com/cyu/rack-cors) to the application’s middleware
stack.

## Singular Resources
Singular resources can be defined as well. If the resource is independent (i.e.,
not nested inside another resource), there is no defined default behavior for
the default actions; you must provide the behavior yourself. Nested singular
resources do have default behavior, however, which is described in the “Nested
Resources” section.

```ruby
Cathode::Base.define do
  resource :product do
    override_action :create do
      # custom creation logic…
    end
  end
end
```

## Nested Resources
Resources can be nested arbitrarily deep inside other resources. When resources
are nested, Cathode uses your models’ associations to determine the default action
behavior. For example, with the following setup, all of a product’s sales would
be returned by the `api/products/{product_id}/sales` endpoint.

```ruby
# app/api/api.rb
resources :products do
  resources :sales, actions: [:index]
end

# app/models/product.rb
class Product < ActiveRecord::Base
  has_many :sales
end

# app/models/sale.rb
class Sale < ActiveRecord::Base
  belongs_to :product
end
```

Here’s how ActiveModel associations map to resourceful endpoints on your API:

Product     | Sale         | Endpoints
----------- | ------------ | --------------------
`has_many`  | `belongs_to` | `products/{id}/sales`, `sales/{id}/product`
`has_one`   | `belongs_to` | `products/{id}/sale`, `sales/{id}/product`
`habtm`     | `habtm`      | `products/{id}/sales`, `sales/{id}/products`

When there is exactly one model attached to the first resource (i.e., a
`has_one` association), you can use all the default actions except `:index`, so
`:show` will return the sale associated with the product, `:create` will create
a new sale and associate it with the product, `:update` will modify the sale,
and `:destroy` will delete it.

When there are many models attached to the resource (i.e., a `has_many` or
`has_and_belongs_to_many` association), you can use the `:index` and `:create`
actions. With a `has_many` on `Product` and a `belongs_to` on `Sale`, `:index`
returns all the sales associated with a product, and `:create` adds a new sale
associated with the product.

For `belongs_to` associations, the `:show` action can be used to return the
associated parent model.

## Replacing & Overriding Default Actions
Of course, you won’t want to use Cathode’s default actions in every scenario.
There are two ways to supply your own behavior:

  * *Replacing* the action allows you to override what the action does but still
    go through the normal Cathode request pipeline, so you’ll still be able to
    use request helpers like `body` and `status`. Use the `replace` method at
    the action level or the `replace_action` method at the resource level.
  * *Overriding* the action allows you to remove the action from Cathode’s
    request pipeline and requires you to do all the processing and rendering
    logic yourself. Overriding an action causes it to be run in the context of
    the *Rails request*, as if you were in a normal controller. You won’t have
    access to any Cathode helpers like `body` and `status`, but you will have
    access to anything a controller would, like `request` and `render`. Use the
    `override` method at the action level or the `override_action` method at the
    resource level. Prefer `replace` over `override`.

```ruby
resources :sales, actions: :all do
  override_action :show do
    render json: Sale.sample
  end
end
```

```ruby
resources :sales, actions: :all do
  replace_action :show do
    body Sale.sample
  end
end
```

## Custom Actions & Non-Resourceful Endpoints
Your API is bound to need actions that don’t map to standard CRUD operations,
and Cathode makes this easy to do. You can define your own actions at both the
version level and the resource level by using the `get`, `post`, `put`, and
`destroy` methods.

Use the `body` and `status` methods to set the response body and HTTP status.
Both of these methods take either a single argument, or a block that will be
evaluated to determine the value. Choose whichever works best in your situation.

```ruby
Cathode::Base.version 1 do
  # sending a different body but the same status
  get :status do
    body { API.alive? ? 'Everything running smoothly' : 'Something has gone wrong' }
    status :ok # not really necessary, since `:ok` is the default
  end

  # sending different body/status depending on the result of a condition
  resources :users do
    get :password_reset_code do
      user = User.find(params[:id])
      if user.present?
        body user.password_reset_code
        status :ok
      else
        body "No user exists with id #{params[:id]}"
        status :bad_request
      end
    end
  end
end
```

Note that custom actions use the `replace` functionality described above by
default. You can use the override functionality instead by using the `override`
and `override_action` methods.

<a name="files_naming"></a>
## Files & Naming Conventions
Cathode is agnostic to the way you organize your API files. Since you can either
define an API all at once using `Cathode::Base.define`, or each version
separately using `Cathode::Base.version`, you have many organization options.
Following are some examples.

### Single file for API
If your API is tiny and you only have a handful of versions, you could place
them all in a single file:

```ruby
# api/api.rb

Cathode::Base.define do
  version 1 do
    resources :products, actions: :all
  end

  version 2 do
    resources :products do
      remove_action :delete
    end

    resources :sales, actions: [:index]
  end
end
```

### Files for each version
To break things apart a bit more, you can use a single file for each version.

```
api/
  v1.rb
  v2.rb
```
```ruby
# api/v1.rb
Cathode::Base.version 1 do
  resources :products, actions: [:index, :show, :delete]
end

# api/v2.rb
Cathode::Base.version 2 do
  resources :products do
    remove_action :delete
  end

  resources :sales, actions: [:index]
end
```

### Folders for each version, files for each resource
Another method would be to have a folder for each version of your API, and files
for each resource:

```
api/
  v1/
    products.rb
  v2/
    products.rb
    sales.rb
```
```ruby
# api/v1/products.rb
Cathode::Base.version 1 do
  resources :products, actions: [:index, :show, :delete]
end

# api/v2/products.rb
Cathode::Base.version 2 do
  resources :products do
    remove_action :delete
  end
end

# api/v2/sales.rb
Cathode::Base.version 2 do
  resources :sales, actions: [:index]
end
```

## License
Cathode is licensed under the MIT license. See
[LICENSE](https://github.com/mobyinc/Cathode/blob/master/LICENSE).

## Related Reading & Projects
* [Versionist](https://github.com/bploetz/versionist)
* [Existing Rails API Solutions Suck](http://joshsymonds.com/blog/2013/02/22/existing-rails-api-solutions-suck/])
* [Grape](https://github.com/intridea/grape)
* [Roar](https://github.com/apotonick/roar)
* [Rails API](https://github.com/rails-api/rails-api)
