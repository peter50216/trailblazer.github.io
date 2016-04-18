---
layout: operation
title: "Grape and Trailblazer"
---

# Grape and Trailblazer

A sample application can be found [on Github](https://github.com/apotonick/gemgem-grape).

## Summary

As Trailblazer provides `Operation` to encapsulate the business logic, and representers for rendering and parsing documents, Grape ends up being leveraged as a routing layer that dispatches to operations.

```ruby
module API
  class Application < Grape::API
    format :json

    version :v1 do
      get("posts")  { run!(Post::Show, request) }
      post("posts") { run!(Post::Create, request) }
    end
  end
end
```
