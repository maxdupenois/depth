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

Not exactly rocket science (not even data science). You
can retrieve the hash with either `base` or `to_h`.

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
  Depth::ComplexHash.new(hash).find(route) # => []
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
  Depth::ComplexHash.new(hash).set(route, 'hello')
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

* `each` = yields `key_or_index` and `fragment`, returns the complex hash
* `select` = yields `key_or_index`, `fragment`, returns a new complex hash
* `reject` = yields `key_or_index`, `fragment`, returns a new complex hash
* `map` = yields `key_or_index`, `fragment` and `parent_type`, returns a new complex hash
* `map_values` = yields  `fragment`, returns a new complex hash
* `map_keys` = yields `key_or_index`, returns a new complex hash
* `map!`, `map_keys!` and `map_keys_and_values!`, returns a new complex hash
* `reduce(memo)` = yields `memo`, `key` and `fragment`, returns memo
* `each_with_object(obj)` = yields `key`, `fragment` and `object`, returns object

_Fragment refers to a chunk of the original hash_

These, perhaps, require a bit more explanation:

#### each

The staple, and arguably the most important, of all the enumeration methods,

```ruby
  hash = { ... }
  Depth::ComplexHash.new(hash).each { |key, fragment| }
```

Each yields keys and associated fragments from the leaf nodes
backwards. For example, the hash:

```ruby
  { '$and' => [{ 'something' => { 'x' => 4 } }] }
```

would yield:

1. `x, 4`
2. `something, { "x" => 4 }`
3. `0, { "something" => {  "x" => 4 } }`
4. `$and, [{ "something" => {  "x" => 4 } }]`

#### select

```ruby
  hash = { 'x' => 1, '$c' => 2, 'v' => { '$x' => :a }, '$f' => { 'a' => 3, '$l' => 4 }}

  Depth::ComplexHash.new(hash).select do |key, fragment|
    key =~ /^\$/
  end
```

The above would yield:

1. `x, 1`
2. `$c, 2`
3. `$x, a`
4. `v, {"$x"=>:a}`
5. `a, 3`
6. `$l, 4`
7. `$f, {"$l"=>4}`

and with the boolean only selecting keys with a dollar sign
it would return a new complex hash

```ruby
{ "$c" => 2, "$f" => { '$l' => 4 } }
```

#### reject

Unsurprisingly this is the inverse of select.

#### map

Map yields both the current key/index and the current fragment,
expecting both returned in an array. I've yet to decide if
there should be a third argument that tells you whether or not
the key/index is for an array or a hash. I've not needed it
but I suspect it might be useful. If it comes up I'll add it.


```ruby
  hash = { '$and' => [{ 'something' => { 'x' => 4 } }] }
  Depth::ComplexHash.new(hash).map do |key, fragment|
    [key, fragment]
  end
```

like `each` the above would yield:

1. `x, 4`
2. `something, { "x" => 4 }`
3. `0, { "something" => {  "x" => 4 } }`
4. `$and, [{ "something" => {  "x" => 4 } }]`

and with the contents being unchanged it would return a
new complex hash with equal contents to the current one.

#### map_values

```ruby
  hash = { '$and' => [{ 'something' => { 'x' => 4 } }] }
  Depth::ComplexHash.new(hash).map_values do |fragment|
    fragment
  end
```

This will yield only the fragments from `map`, useful if
you only wish to alter the value parts of the hash.

#### map_keys

```ruby
  hash = { '$and' => [{ 'something' => { 'x' => 4 } }] }
  Depth::ComplexHash.new(hash).map_keys do |key|
    key
  end
```

This will yield only the keys from `map`, useful if
you only wish to alter the keys.

#### map!, map_keys!, map_values!

The same as their non-exclamation marked siblings save that
they will cause the complex hash on which they operate to change.

#### reduce and each_with_object

Operate as you would expect. Can I take a moment to point out how
irritating it is that `each_with_object` yields the object you pass
in as its last argument while `reduce` yields it as its first O_o?

```ruby
  hash = { '$and' => [{ 'something' => { 'x' => 4 } }] }
  Depth::ComplexHash.new(hash).reduce(0) do |memo, key, fragment|
    memo += 1
  end

  Depth::ComplexHash.new(hash).each_with_object([]) do |key, fragment, obj|
    obj << key
  end
```

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

