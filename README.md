**This gem is under heavy development and is not ready to be used in product
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
* Deprecation
* Auto-documentation

## Getting Started
To generate the `api` directory and mount the engine:
```ruby
rails generate cool
```

*Note: Your API can be defined using the `resource` method in your `api/api.rb` file,
using separate files and the `Cathode::API` class, or a combination of both. For
brevity, this document uses `resource` with the assumption that everything is in
`api.rb`. See the section below, “Files & Naming Conventions,” for details on
using the other method.*

In the simplest case, you can use only default actions:
```ruby
resource :products, actions: [:index, :show, :search]
```

Contrary to Rails’s `routes.rb` file–in which the default actions are included
unless explicitly excluded–only actions that you specify are defined. Out of
the box, the actions available are: `:index, :show, :create, :update, :delete, :search`.

In this case, the following routes are created: `get api/products/`, `get
api/products/{id}`, and `get api/products/search`. By default, all products will
be returned in the `index` call, and no permissions will be enforced on the
`show` call. By default, the `search` call will take a `query` parameter and
search for it using the `Product.title` field.

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
  resource :products
    remove_action :search
  end
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

## Params
All actions have access to the request `params` hash.

## Custom action behavior
Of course, you won’t want to use Cathode’s default actions in every scenario.

```ruby
version 2.1 do
  resource :sales, actions: [:all] do
    action :show do
      change 'Checks user permission'
      access_filter do |current_user|
        resource.user == current_user
      end
    end
  end
end
```

In this case, we need to prevent users from seeing sales that aren’t theirs.
Happily, Cathode provides some neat shorthands for common scenarios like this.
`access_filter` can be applied to any action, and should be a method that
returns `true` if the user can access the resource and `false` if not. If the
user cannot access the resource, a `401 Unauthorized` header will be sent.

In those cases where you want to do all of the logic yourself, and just want the
endpoints that Cathode generates, you can override an action entirely:

```ruby
resource :sales, actions: [:all] do
  # show a random sale instead
  override_action :show do
    render json: Sale.sample
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
While this example has been putting all actions in a single file, in reality
you’ll probably want to specify individual files for each resource. You can use
the same versioning scheme in those files; as long as your resource APIs inherit
from `Cathode::API`, Cathode will match up everything accordingly:

```ruby
# app/api/products_api.rb

class ProductsAPI < Cathode::API
  actions: [:index, :show, :search] # version 1.0.0 is implied

  version 2 do
    remove_action :search
  end
end
```

Since nothing about products changed in version 1.2 (which only added sales,
above), it will use the same actions as it did in version 1. In version 2,
everything is carried over except for the `search` endpoint.

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
