# Roadmap
## Todo
* Querying
* Pre-defined subactions on :index (paging, cursoring, etc)
* Auto-loading in Rails w/o hardcoding the api/ dir
* Real authentication – perhaps integrate w/ CanCan or similar
* Deprecation messages
* Auto-documentation / changelog
* Support for other ORMs
* Support for Rails 3.2 + StrongParams gem
* Support for multiple API instances

## Querying
Cathode’s querying functionality can be used to send robust read-only queries
to your API. To allow querying a resource, make sure the `:query` action is
available on that resource:

```ruby
Cathode::Base.define do
  resources :products, actions: [:query]
end
```

Your API client can now make a `GET` request to the `/api/products/query`
endpoint to initiate a query:
```bash
curl api/products/query?query={query}
```

`{query}` must be a string describing a query according to Cathode’s query DSL.

### The Query DSL
The DSL consists of groups of clauses. Each query must have at least one clause,
but may contain as many as you wish.

```
clause[, clause2[, clause3, …]]
```

A clause is a group of words that describe the query to be performed on the
resource. The available clauses are:

* `where {condition}`: use for finding resources that match one or more conditional
  expressions
* `sort {sort_field} asc|desc`: after filtering by any `where` clauses, sort
  the records by `sort_field` and order by `{order}` (the default is `asc`)
* `limit {max_records}`: return as many as `max_records` records

### Conditional Expressions
The `where` clause supports a wide variety of expressions.

* `{field} before|after {time}`: find records whose `field` attribute is before
  or after a given `time`. `time` is run through [Chronic](https://github.com/mojombo/chronic),
  so supports many natural ways of specifying times.
* `{field} <, <=, ==, !=, >=, > {value}`: find records whose `{field}` attribute
  is (respectively) less than, less than or equal to, equal to, not equal to,
  greater than or equal to, or greater than, the given `value`. 
* `{field} in [{value1, value2, …}]`: find records whose `{field}` attribute is
  in the given array
* `{field} !in [{value1, value2, …}]`: find records whose `{field}` attribute is
  not in the given array

`{field}` itself can also be a `where` clause, adding the ability to use
sub-queries.

If a `where`, `sort`, or `limit` keyword is not in a clause, the assumption is
that it’s a `where` clause.

### Examples
```bash
# the past week’s sales
curl api/sales/query?query='where created_at after 1 week ago'

# products with more than 5 sales
curl api/products/query?query='where sales.count > 5'

# products sorted by name ordered Z-A limited to 20 records
curl api/products/query?query='sort name desc, limit 5'

# products with ‘battery’ in their name
curl api/products/query?query='where {battery} in name'

# products without ‘battery’ in their name that haven’t had a sale in the past month
curl api/products/query?query='
  {battery} !in name,
  sales.where(created_at after 1 month ago).count == 0
'

# the 5 best-selling products that cost between $200-$500
curl api/products/query?query='
  cost >= 200,
  cost <= 500,
  sort sales.count desc,
  limit 5
'
```

## Documentation & Changelogs
By sticking to Cathode’s versioning scheme, you tell it a lot about your API. So
much, in fact, that we can use it to automatically generate documentation for
all versions of your API and generate a changelog. Running `rake cathode:docs` will
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
