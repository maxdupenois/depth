# Depth

Depth is a utility gem for deep manipulation of complex hashes, that
is nested hash and array structures. As you have probably guessed it
was originally created to deal with a JSON like document structure.
Importantly it uses a non-recursive approach to its enumeration.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'depth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install depth

## Usage

### The complex hash

```ruby
  hash = { '$and' => [
    { '#weather' => { 'something' => [], 'thisguy' => 4 } },
    { '$or' => [
      { '#otherfeed' => {'thing' => [] } },
    ]}
  ]}
```
_Nicked from a query engine we're using on Driftrock_

The above is a sample complex hash, to use the gem to
start manipulating it is pretty simple:

```ruby
complex_hash = Depth::ComplexHash.new(hash)
```

Not exactly rocket science (not even data science).

### Manipulation

Manipulation of the hash is done using routes. A route
being a description of how to traverse the hash to
get to this point.

The messages signatures relating to manipulation are:

* `set(route, value)` = Set a value
* `find(route)` = Find a value
* `alter(route, key:)` = Alter a key (the last key in route)
* `alter(route, value:)` = Alter a value, identical to `set`
* `alter(route, key: value:)` = Alter a key and value, identical to a `set` and then `delete`
* `delete(route)` = Delete a value

Routes can be defined as an array of keys or indeces:

```ruby
  hash = { '$and' => [
    { '#weather' => { 'something' => [], 'thisguy' => 4 } },
    { '$or' => [
      { '#otherfeed' => {'thing' => [] } },
    ]}
  ]}
  route = ['$and', 1, '$or', 0, '#otherfeed', 'thing']
  ComplexHash.new(hash).find(route) # => []
```

But there's something cool hidden in the `set` message,
if part of the structure is missing, it'll fill it in as it
goes, e.g.:

```ruby
  hash = { '$and' => [
    { '#weather' => { 'something' => [], 'thisguy' => 4 } },
    { '$or' => [
      { '#otherfeed' => {'thing' => [] } },
    ]}
  ]}
  route = ['$and', 1, '$or', 0, '#sup', 'thisthing']
  ComplexHash.new(hash).set(route, 'hello')
  puts hash.inspect #=>
  # hash = { '$and' => [
  #   { '#weather' => { 'something' => [], 'thisguy' => 4 } },
  #   { '$or' => [
  #     { '#otherfeed' => {'thing' => [] } },
  #     { '#sup' => {'thisthing' => 'hello' } },
  #   ]}
  # ]}
```

Great if you want it to be a hash, but what if you want to add
an array, no worries, just say so in the route:

```ruby
  route = ['$and', 1, '$or', 0, ['#sup', :array], 0]
  # Routes can also be defined in other ways
  route = ['$and', 1, '$or', 0, { key: '#sup', type: :array }, 0]
  route = ['$and', 1, '$or', 0, RouteElement.new('#sup', type: :array), 0]
```

### Enumeration

The messages signatures relating to enumeration are:

* `each` = yields `key_or_index` and `fragment`
* `map` = yields `fragment`, returns a new complex hash
* `map_keys` = yields `key_or_index`, returns a new complex hash
* `map_keys_and_values` = yields `key_or_index`, `fragment` and `parent_type`, returns a new complex hash
* `map!`, `map_keys!` and `map_keys_and_values!`, returns a new complex hash
* `reduce(memo)` = yields `memo`, `key` and `fragment`, returns memo
* `each_with_object(obj)` = yields `key`, `fragment` and `object`, returns object

More information coming soon...

## Why?

Alright, we needed to be able to find certain keys
from all the keys contained within the complex hash as said keys
were the instructions as to what data the hash would be able to match
against. This peice of code was originally recursive. We were adding
a feature that required us to also be able to edit these keys, mark
them with a unique identifier. As I was writing this I decided I wasn't
happy with the recursive nature of the key search as we have no guarantees
about how nested the hash could be. As I refactored the find and built
the edit it became obvious that the code wasn't tied to the project at
hand so I refactored it out to here.


## Contributing

1. Fork it ( https://github.com/[my-github-username]/depth/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

