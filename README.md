## Under Alpha Construction...coming soon within a few weeks

# SoftActive

A lightweight soft delete without delting the row in ActiveRecord models. 

## Installation

Supported on Ruby 1.9.3 and Rails 3.X (ActiveRecord)

Add this line to your application's Gemfile:

    gem 'soft_active'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soft_active

## Usage (Rails 3.X)

### Model Definition

You can enable SoftActive like this in an ActiveRecord model:

```ruby
class Posts < ActiveRecord::Base
  soft_active 
end
```

You can also specify column name and other options like here:
```ruby
class Posts < ActiveRecord::Base
  soft_archive :column => :active, :dependent_cascade => true
end
```

`:column` by default assumed to be `:active` but you can specify your own. At this time it must be a boolean column type. Other types will be supported in future.

`:dependent_cascade` by default assumed to be `false`. If true, any setting and unsetting will cascade to ':dependent => :destroy' associations. Only direct chindren associations are checked i.e. dependency is ignored if `:through` option is used for the association. Any save after set/unset will also cascade to dependent associations. 

Class/Relation level methods or scopes available:

`Post.only_inactive` - Scope that shows only inactive rows

`Post.with_inactive` - Scope shows all rows active and inactive

`Post.only_active` - Scope that shows only active rows

`Post.scoped` - Default scope - same as `only_active`

Also a class level method `Post.soft_active?` returns true if soft active is enabled for the model.


### Row operations - soft active/inactive

Default records have active as true, but they can be explicitly set and unset using instance methods.

To set active:

```ruby
p = Post.first
p.set_active
```

To set inactive:

```ruby
p = Post.with_inactive.first
p.unset_active
```

To check active/inactive:

```ruby
p = Post.unscoped.first
p.is_active?
```

## License
Copyright © 2012 LearnZillion, Inc. Released under the MIT license

## Copyright
Copyright © 2012 LearnZillion, Inc.
