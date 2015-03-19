# Depth

Depth is a utility gem for deep manipulation of complex hashes, that
is nested hash and array structures. As you have probably guessed it
was originally created to deal with a JSON like document structure.


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

Coming soon...

### Enumeration

Coming soon...

## Contributing

1. Fork it ( https://github.com/[my-github-username]/depth/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

