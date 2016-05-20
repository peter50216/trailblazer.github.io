---
layout: operation
title: Trailblazer in 20 Minutes
---

# Trailblazer in 20 minutes

This guide only describes a *Create* operation. The same applies to all kinds of other functions, such as updating or deleting. We only had 20 minutes.


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


NOTE ABOUT DIFFERENT LAYERS (new abstractions, exciting!!!!)

While those steps usually happen in a linear flow, one layer instructing the next, Trailblazer also exposes a _vertical layer_ for *Authentication*. In Trailblazer, authentication of arbitraty steps is something we've thought about before.

The Trailblazer architecture provides one layer per responsibility. Following that approach will lead to controllers being empty HTTP endpoints, lean models with persistence-relevant scopes, finders and associations, only, and a handful of new, exciting objects helping you to implement the business.

## Operation / Structure / Hooking to Endpoint

Every application is a set of functions (or _"features"_) that can be triggered by the user. This could be viewing a comment, updating a user's details, following a draft beer shop, or importing a CSV file of bean grinders into a database.

Each function is implemented with one public operation. Operations are objects. This means, **for every feature of your app, you will write an operation** class which is then hooked to the framework's endpoint.

The great thing about that is: You can also introduce operations step-wise into existing systems and replace legacy code or add new features using operations and cells.

## Controller

Every web framework has the concept of *controllers*: Endpoints hooked to a HTTP route. For example, this could be a Rails controller action invoked via a `POST /comments` request.

The code you would usually put into the intercepting action method, such as creating an object, assigning request parameters to it, and so on, does no longer live there.

Instead, an **endpoint simply dispatches to its operation**.

```ruby
class CommentsController < ApplicationController
  def create
    Comment::Create.(params)
    # you still have to take care of rendering.
  end
```

Trailblazer leverages Ruby's namespacing the way it was intended to be used. This is why the operation's constant name is `Comment::Create`.

Another confusing "dialect" is the way objects are invoked in Trailblazer. `Create.(params)` is also known as the *call style*, as it resolves to `Create.call(params)`.

You might have noticed that there's no instantiation of the operation happening. This is done internally. Exposing only one public method is a concept adopted from functional programming: Since there's only one way to invoke an operation, you simply can't confuse method orders or mess with internal state.

What you pass into the operation is absolutely your business (no pun intended). In web applications, this will usually be the `params` hash. Note that this completely **decouples an operation from HTTP**. You could use it in a background task or an event-loop system, too - the operation expects a hash as input, nothing more.

## Operation

The `Comment::Create` operation is a class taking care of the entire process of creating, validating, and persisting a comment.

Don't confuse this with a _god class_, though. An **operation is an orchestrating object** that instructs smaller objects like representers, a form object or the persistent model to accomplish that! It knows how to wire together those stakeholders but leaves the specific implementation up to them.

```ruby
class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    model Comment, :create

    contract do
      property :body
      property :author_id

      validates :body, presence: true
    end

    def process(params)
      validate(params[:comment]) do
        contract.save
      end
    end
  end
end
```

Operations are always namespaced into their *concept*. In Rails, very often, this happens to be the model's constant name. The `Create` class sits in the `Comment` ActiveRecord constant. This is simple Ruby namespacing and should in no way be confused with inheritance.

Every operation needs to implement the `process` method. Here, the business code happens and the orchestration takes place.

The `Operation` class offers you the `validate` method to deserialize and validate the incoming data. To do so, the operation uses its form object, also known as *contract* in Trailblazer.

## Contract

Since it is very common for operations to use a contract for validation, you can define contracts inline using the declarative `contract` class method.

```ruby
class Create < Trailblazer::Operation
  # ..
  contract do
    property :body
    property :author_id

    validates :body, presence: true
  end
```

A contract is simply a [Reform class](/gems/reform). **It allows to specify the fields of the input, and validations specific to that operation.**

Explicitly declaring incoming fields is very important in Trailblazer. When validating the input, the contract will only respect the defined, or whitelisted, fields and ignore unsolicited data in the input. This is why you don't need solutions like `strong_parameters` anymore.

Validations can be defined using [ActiveModel::Validations](http://guides.rubyonrails.org/active_record_validations.html) or the new [dry-validation](/gems/reform/validation.html#dry-validation) engine.

## Validation

To validate the incoming `params`, the `validate` method in the operation enters the stage.

```ruby
class Create < Trailblazer::Operation
  # ..
  def process(params)
    validate(params[:comment]) do
      # ..
    end
  end
```

In case of a successful validation, the block passed to `validate` is invoked.

The operation's `validate` first instantiates the contract, which is really just a Reform object. Then, the incoming data is written to the contract object (this is called *deserialization*) and afterwards, validation of the entire object graph is performed using the Reform API.

The whole process of validation happens internally, but can be easily customized. An important fact here is that the contract graph is an intermediate object - **instead of writing input to the model, this all happens on the contract**. The model is not accessed at all for validation.

Having a dedicated contract object sitting between operation and model is why your model classes will end up as a pure persistence layer.

```ruby
class Comment < ActiveRecord::Base
  belongs_to :author
end
```

Validation code sits in the contract, callbacks are defined in operation or callback objects.

## Persistence

After having validated data, to persist it, a model object is needed. In most Rails applications, this will be an `ActiveRecord` model, but many Trailblazer projects use alternative libraries such as [Sequel](http://sequel.jeremyevans.net/) or [ROM](http://rom-rb.org/).

You're free to create or retrieve models yourself. However, the operation offers you a trivial API to create a model when it is needed.

```ruby
class Create < Trailblazer::Operation
  model Comment, :create # will assign @model = Comment.new
```

Having the validated data sitting on the contract object, it is a good idea to push the data to the model and save it. This, again, happens using the contract's API.

```ruby
class Create < Trailblazer::Operation
  # ..
  def process(params)
    validate(params[:comment]) do
      contract.save
    end
  end
```

**The model is now populated with the validated data, and saved to the database.** Very simple mechanics happen behind the scene and can easily be changed, if you disagree with Trailblazer's flow.

## Callback

Often after persisting, additional logic needs to be executed. This is known as *post-processing* or *callbacks* in Trailblazer. Instead of polluting the model or controller with this code, callbacks live in the operation.

They are literally called when you need them.

```ruby
class Create < Trailblazer::Operation
  # ..
  def process(params)
    validate(params[:comment]) do
      contract.save

      after_save!
    end
  end

private
  def after_save!
    Comment::Notifier.mail(model)
  end
```

Callbacks can be methods on the operation, separate callback objects, using [Trailblazer's callback API](http://trailblazer.to/gems/operation/callback.html), or even advanced transactional gems like the excellent [dry-transaction](https://github.com/dry-rb/dry-transaction).

## Test

Trailblazer and its operation design makes it extremely simple to unit-test your application's behavior. **All business code is tested via operation tests.**

```ruby
describe Comment::Create do
  it "persists valid input" do
    op = Comment::Create.(comment: { body: "TRB rocks!", author_id: 1 })

    op.model.persisted?.must_equal true
    op.model.body.must_equal "TRB rocks!"
  end
end
```

Operations are also used as factories in Trailblazer applications. This will assure that your test application state is always identical to a realistic production state.

```ruby
let(:user)    { User::Create.(user: attributes_for(:user)).model }
let(:comment) { Comment::Create.(comment: { body: "Yo!", author_id: user.id} ) }
```

Gone are the times of leaky factories. Gems such as [factory_girl](https://github.com/thoughtbot/factory_girl) can be used to provide input hashes, only.

Trailblazer also abandons controller tests, in favor of strict integration tests. This minimizes testing to integration and operation tests.

## File Structure

Files for the additional abstraction layers are no longer organized by technology. Trailblazer introduces the idea of *concepts*, which group files by a set of features.

```
app
├── concepts
│   ├── comment
│   │   ├── contract
│   │   │   ├── create.rb
│   │   │   └── update.rb
│   │   ├── cell
│   │   │   └── new.rb
│   │   ├── operation
│   │   │   ├── create.rb
│   │   │   └── update.rb
│   │   └── view
│   │       ├── new.haml
│   │       └── show.haml
```

A concept could be comments, blog posts, image galleries or abstract workflows. At the same time, operations are not limited to CRUD. They often are named `Job::Apply` or `User::Follow` and help with a domain-oriented software design.

## View (UI)

While the operation is the pivotal element for the business processing, Trailblazer also comes with a drop-in replacement for views. Object-oriented [view models](/gems/cells) encapsulate fragments of the web UI and make it easier to deal with complexity.

Those *cells* are usually rendered from the controller.

```ruby
class CommentsController < ApplicationController
  def show
    comment = Comment::Cell.present(params)

    render Comment::Cell::New, comment, layout: Application::Layout
  end
```

View models, or cells, are classes.

```ruby
module Comment::Cell
  class New < Trailblazer::Cell
    property :body

    def author_name
      model.author.full_name || "Anonymous"
    end
  end
end
```

Helpers as known from Rails do not exist anymore. Instead, instance methods of the cell can be used in the view.

```haml
%h1 Comment

.row
  = body
.row
  = author_name
```

View models in Trailblazer are provided by the [Cells gem](/gems/cells) which is completely decoupled from Trailblazer. It also works fine in other frameworks like Hanami or Sinatra.
