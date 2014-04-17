**This gem is under heavy development and is not ready to be used in production
systems.**

# Cathode
Cathode is a gem for Rails projects that generates API boilerplate for REST
applications.

## Features
* Automatically generate endpoints (routes + controllers) for common RESTful
  actions:
  * Listing resources, optionally filtered and paginated
  * Finding a single resource
  * Creating a new resource
  * Updating a resource
  * Deleting a resource
* Endpoints respond to JSON and output JSON by default (possibly add XML et al later on?)
* Versioning of endpoints

## Roadmap
* Custom actions on resources and versions (aka arbitrary endpoints)
* Pre-defined subactions on :index (paging, cursoring, etc)
* Real authentication – perhaps integrate w/ CanCan or similar?
* Deprecation messages
* Auto-documentation / changelog

## Getting Started
Install the gem:

```bash
gem install cathode
```

Mount the engine in your `config/routes.rb` file:
```ruby
mount Cathode::Engine => '/api' # use a namespace of your choice
```

## Defining Your API
Cathode’s DSL provides an easy way to define your API’s versions and the
resources inside of them.

```ruby
Cathode::Base.define do
  # version 1.0.0 is implied if no version block is given
  resource :products, actions: [:index, :show, :search]

  version '1.0.1' do
    resource :sales, actions: [:all]
  end
end
```

Contrary to Rails’s `routes.rb` file–in which the default actions are included
unless explicitly excluded–only actions that you specify are defined. Out of
the box, the actions available are: `:index, :show, :create, :update, :delete, :search`.

In version 1, the following routes are created: `get api/products/`, `get
api/products/{id}`, and `get api/products/search`. By default, all products will
be returned in the `index` call, and no permissions will be enforced on the
`show` call. By default, the `search` call will take a `query` parameter and
search for it using the `Product.title` field.

In version 1.0.1, routes are created for the `sales` endpoint: `get api/sales/`,
`get api/sales/{id}`, etc. Those endpoints are not accessible in version 1.
However, because versions cascade, the routes on the `products` endpoint are all
accessible in version 1.0.1.

### Strong parameters for `create` and `update` actions
Because ActiveModel prevents you from writing non-whitelisted attributes, you’ll
need to specify a strong parameters block when you define a `create` or `update`
action. The request `params` are passed to the block, and you can use the
[Strong Parameters](https://github.com/rails/strong_parameters) API just as you
would in a controller.

```ruby
# use the same attribute whitelist for `create` and `update`
resource :products do
  attributes do |params|
    params.require(:product).permit(:title, :description, :cost)
  end
end

# use different attribute whitelists for `create` and `update`
resource :products do
  action :create do
    attributes do |params|
      params.require(:product).permit(:title, :description, :cost)
    end
  end

  action :update do
    attributes do |params|
      params.require(:product).permit(:description, :cost)
    end
  end
end
```

Requests that attempt to write non-whitelisted attributes will respond with `400
Bad Request`.

## Serialization
Cathode doesn’t do any explicit serialization of resources when responding to
requests. However, it does use `render: json`, which will invoke [ActiveModel
serializers](https://github.com/rails-api/active_model_serializers) if you’ve
defined them.

## Versioning
Versioning is encouraged to prevent you from introducing breaking API changes.
Your API’s versions should use [Semantic Versioning](http://semver.org/), which
enables Cathode to deduce patches, non-breaking changes, and breaking changes. Cathode
also makes it easy to deprecate all or part of any version of your API at any
time.

If you define your resources without any versions, Cathode assumes it’s version
`1.0.0` of your API. When you’re ready to introduce changes, you can
easily provision a new version:

```ruby
resource :products, actions: [:index, :show, :search]

version 1.1 do
  resource :sales, actions: [:all]
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

## Goodies on the `index` action
By default `index` actions return all records in your resource’s default scope.
However, common operations–like filtering, sorting, pagination, cursoring,
etc–are also supported. For example, an application might make the following API
call:

```ruby
GET /api/products?query=flashlight&sort=desc&page=5
```

To add support for this functionality in Cathode, just flip on querying, sorting,
and paging in the `index` action:

```ruby
resource :products do
  action :index do
    allows :querying, :sorting, :paging
  end
end
```

## Overriding default actions
Of course, you won’t want to use Cathode’s default actions in every scenario. To
use your own logic, either use the `override_action` method at the resource
level, or the `override` method inside an action block. For example, to show a
random sale instead on the `show` action, these are functionally equivalent:

```ruby
resource :sales, actions: [:all] do
  override_action :show do
    render json: Sale.sample
  end
end
```

```ruby
resource :sales, actions: [:all] do
  action :show do
    override do
      render json: Sale.sample
    end
  end
end
```

The `override` and `override_action` blocks have access to anything the
controller would normally have access to, so you can use `request`, `response`,
and `params` normally. Note that overriding means the request won’t go through
Cathode’s regular pipeline, so you must render the response manually.

## Custom actions & non-resourceful endpoints
Your API is bound to need actions that don’t map to standard CRUD operations,
and Cathode makes this easy to do. You can define your own actions at both the
version level and the resource level.

Use the `body` and `status` methods to set the response body and HTTP status.
Both of these methods take either a single argument, or a block that will be
evaluated to determine the value. Choose whichever works best in your situation.

```ruby
Cathode::Base.version 1 do
  # sending a different body but the same status
  action :status do
    body { API.alive? ? 'Everything running smoothly' : 'Something has gone wrong' }
    status :ok # not really necessary, since `:ok` is the default
  end

  # sending different body/status depending on the result of a condition
  resource :users do
    action :password_reset_code do
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

## Deprecation
With Cathode’s slick versioning, you’ll be implicitly deprecating junk in previous
versions each time you introduce a new breaking change. When that happens, users
of previous versions of your API should be told that a feature they’re using is
deprecated. By default, Cathode will respond with a deprecation warning for those
users. So users of version `1.1` of your API would receive the following
response when making a call to `/api/products/search`:

```json
{
  "products": [ array of the products found… ]
  "messages": [
    "The search endpoint is deprecated and is removed in version 2.0.0 of the
API"]
}
```

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
    resource :products, actions: [:all]
  end

  version 2 do
    resource :products do
      remove_action :delete
    end

    resource :sales, actions: [:index]
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
  resource :products, actions: [:all]
end

# api/v2.rb
Cathode::Base.version 2 do
  resource :products do
    remove_action :delete
  end

  resource :sales, actions: [:index]
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
  resource :products, actions: [:all]
end

# api/v2/products.rb
Cathode::Base.version 2 do
  resource :products do
    remove_action :delete
  end
end

# api/v2/sales.rb
Cathode::Base.version 2 do
  resource :sales, actions: [:index]
end
```

## Documentation & Changelogs
By sticking to Cathode’s versioning scheme, you tell it a lot about your API. So
much, in fact, that we can use it to automatically generate documentation for
all versions of your API and generate a changelog. Running `cool docs` will
generate the documentation at `docs/api/1.0.0`, `docs/api/1.1.0`,
`docs/api/2.0.0`, and `docs/api/2.1.0`. It will also automatically add a
`Changelog`:

```markdown
# Changelog
## Version 2.1.0
Checks user permission in `sales#show`.

## Version 2.0.0
Removes the `search` endpoint from `products` resource.

## Version 1.1.0
Adds `sales` resource with the following endpoints:
- `GET /api/sales`
- `GET /api/sales/{id}`
- `GET /api/sales/search`
- `POST /api/sales`
- `PUT /api/sales/{id}`
- `DELETE /api/sales/{id}`

## Version 1.0.0
Initial release

Adds `products` resource with the following endpoints:
- `GET /api/products`
- `GET /api/products/{id}`
- `GET /api/products/search`
- `POST /api/products`
- `PUT /api/products/{id}`
- `DELETE /api/products/{id}`
```

## Related Reading & Projects
* [Versionist](https://github.com/bploetz/versionist)
* [Existing Rails API Solutions Suck](http://joshsymonds.com/blog/2013/02/22/existing-rails-api-solutions-suck/])
* [Grape](https://github.com/intridea/grape)
* [Roar](https://github.com/apotonick/roar)
* [Rails API](https://github.com/rails-api/rails-api)
