---
layout: operation
title: Trailblazer in 20 Minutes
---

# Trailblazer in 20 minutes

Announcing itself as a *High-Level Architecture*, Trailblazer aims to help software teams to implement the actual business logic of their applications.

In Trailblazer, we understand business logic as anything that happens after intercepting the HTTP request, and returning a response document.

Trailblazer leaves dealing with HTTP and instructing the rendering up to the *infrastructure framework*: This could be any library you like, Rails, Hanami, Sinatra or Roda.

Business code is encapsulates into *operations*, the fundamental and pivotal element in Trailblazer. Operations gently force you to decouple your application code from the framework. This is why your code ideally doesn't care about the underlying framework anymore.


## Flow

A typical business workflow is structured into five steps.

* Deserialization
* Validatio
* Persistence
* Post-Processing (aka callbacks)
* Rendering

While those steps usually happen in a linear flow, one layer instructing the next, Trailblazer also exposes a _vertical layer_ for *Authentication*. In Trailblazer, authentication of arbitraty steps is something we've thought about before.

The Trailblazer architecture provides one layer per responsibility. Following that approach will lead to controllers being empty HTTP endpoints, lean models with persistence-relevant scopes, finders and associations, only, and a handful of new, exciting objects helping you to implement the business.

## Operation / Structure / Hooking to Endpoint

Every application is a set of functions (or features) that can be triggered by the user. This could be viewing a comment, updating a user's details, following a draft beer shop, or importing a CSV file of bean grinders into a database.

Each function is implemented withn one operation. Operations are objects. In turn, for every feature of your app, you will write an operation class which is then hooked to the framework's endpoint.

The great thing about that is: You can also introduce operations step-wise into existing code and replace legacy code or add new features using operations and cells.

## Controller

Every web framework has the concept of *controllers*. Endpoints hooked to a HTTP route. For example, this could be a Rails controller action invoked via a `POST /comments` request.

The code you would usually put into the intercepting action method, such as creating an object, assigning request parameters to it, and so on, does no longer live there.

Instead, an endpoint simply dispatches to an operation.

```ruby
class CommentsController < ApplicationController
  def create
    Comment::Create.(params)
    # you still have to take care of rendering.
  end
```



Also, note that an operation doesn't even know about HTTP. You could use it in a background task or an event-loop system - the environment is up to you.

