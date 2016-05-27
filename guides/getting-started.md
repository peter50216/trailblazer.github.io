---
layout: guide
title: Getting Started
---

# Getting Started With Trailblazer

This document lists all steps necessary to get Trailblazer up and running in new or existing applications.

## Gems

As Trailblazer is highly modular, you have to make sure you include the correct gems in your `Gemfile`.

Here's a `Gemfile` example for a Rails application.

```ruby
gem "trailblazer"
gem "trailblazer-rails"

gem "reform", "2.2.0"    # optional, allows to specify specific version.
gem "reform-rails"

# optional, in case you want Cells.
gem "trailblazer-cells"
gem "cells-erb"         # Or cells-haml, cells-slim, cells-hamlit.
gem "cells-rails"
```

## Other Frameworks

Here's a sample `Gemfile` for a non-Rails project that doesn't use `Active*`.

```ruby
gem "trailblazer"
gem "trailblazer-loader" # optional, if you want us to load your concepts.

gem "reform", "2.2.0"
gem "dry-validation", ">= 0.7.0"

# optional, in case you want Cells.
gem "trailblazer-cells"
gem "cells-erb"         # Or cells-haml, cells-slim, cells-hamlit.
```

Note that you need to invoke the loader manually. Usually, this would happen in an initializer.

```ruby
Trailblazer::Loader.new.(concepts_root: "./concepts/") do |file|
  require_relative(file)
end
```
