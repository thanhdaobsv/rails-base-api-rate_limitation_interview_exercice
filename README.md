# Skeleton for new Rails 4 application for REST API

[![Code Climate](https://codeclimate.com/github/fs/rails-base-api.png)](https://codeclimate.com/github/fs/rails-base-api)
[![Build Status](https://semaphoreci.com/api/v1/fs/rails-base-api/branches/master/shields_badge.svg)](https://semaphoreci.com/fs/rails-base-api)

This simple application includes ruby/rails technology which we use at FlatStack for new REST API projects.

Application currently based on Rails 4 stable branch and Ruby 2.3.3

## API

Status of the API could be checked at [http://localhost:5000/docs](http://localhost:5000/docs)

## What's included

### Application gems:

* [Decent Exposure](https://github.com/voxdolo/decent_exposure) for DRY controllers
* [Rollbar](https://github.com/rollbar/rollbar-gem) for exception notification
* [Thin](https://github.com/macournoyer/thin) as rails web server
* [Kaminari](https://github.com/amatsuda/kaminari) for pagination
* [Rack CORS](https://github.com/cyu/rack-cors) for [CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing)
* [Redis](https://github.com/redis/redis-rb) for store endpoint requested information by an user


### Development gems

* [Foreman](https://github.com/ddollar/foreman) for managing development stack with Procfile
* [Letter Opener](https://github.com/ryanb/letter_opener) for preview mail in the browser instead of sending
* [Mail Safe](https://github.com/myronmarston/mail_safe) keep ActionMailer emails from escaping into the wild during development
* [Bullet](https://github.com/flyerhzm/bullet) gem to kill N+1 queries and unused eager loading
* [Rails Best Practices](https://github.com/railsbp/rails_best_practices) code metric tool
* [Brakeman](https://github.com/presidentbeef/brakeman) static analysis security vulnerability scanner
* [Bundler Audit](https://github.com/rubysec/bundler-audit) Patch-level verification for Gems
* [Spring](https://github.com/rails/spring) for fast Rails actions via pre-loading

### Testing gems

* [Factory Girl](https://github.com/thoughtbot/factory_girl) for easier creation of test data
* [RSpec](https://github.com/rspec/rspec) for awesome, readable isolation testing
* [Shoulda Matchers](http://github.com/thoughtbot/shoulda-matchers) for frequently needed Rails and RSpec matchers
* [Email Spec](https://github.com/bmabey/email-spec) Collection of rspec matchers and cucumber steps for testing emails
* [Rspec Api Documentation](https://github.com/zipmark/rspec_api_documentation) Generate pretty API docs for your Rails APIs

### Initializes

* `01_config.rb` - shortcut for getting application config with `app_config`
* `mailer.rb` - setup default hosts for mailer from configuration
* `requires.rb` - automatically requires everything in lib/ & lib/extensions
* `rack_cors.rb` - setup whitelist of domains to allow cross-origin resource sharing

### Scripts

* `bin/setup` - setup required gems and migrate db if needed
* `bin/quality` - runs rubocop, brakeman, rails_best_practices and bundle-audit for the app
* `bin/ci` - should be used in the CI or locally
* `bin/server` - to run server locally


## Quick start

Clone application as new project with original repository named "rails-base-api"

```bash
git clone git://github.com/fs/rails-base-api.git --origin rails-base-api [MY-NEW-PROJECT]
```

Create your new repo on GitHub and push master into it.
Make sure master branch is tracking origin repo.

```bash
git remote add origin git@github.com:[MY-GITHUB-ACCOUNT]/[MY-NEW-PROJECT].git
git push -u origin master
```

Run setup script

```bash
bin/setup
```

Make sure all test are green

```bash
bin/ci
```

Run app

```bash
bin/server
```



## Interview Exercice

###API with rate limitation


We are given you here a RoR API application that allows to manage a simple blog.
The API and project setup is already implemented. you have authentication for all endpoints and you can manage Posts and Comments via the following API calls:

- POST /login
- GET /posts
- GET /posts/:post_id
- POST /posts
- GET /posts/:post_id/comments
- POST /posts/:post_id/comments
- PUT /posts/:post_id/comments/:comment_id
- DELETE /posts/:post_id/comments/:comment_id

Given this API, you should implement a rate limitation system that allows to control finely how many calls per period a user can make.

These are the requirements for the work:

1 - An authenticated user can only make x API calls per rate limit window. By default x = 15 and the default rate limit window is 15 sec, so by default a user can make 15 requests / 15sec. Take into account that some endpoints might need different rate limit configuration (see point 4)

2 - The API must return an rate limit error when the limit has been reached

3 -  Application needs to be tested

4 - The rate limit configuration must be easily configurable (a user interface is not needed). To give you an example, you will configure it with this default settings:

- POST /posts:  x = 2, limit_window = 60. (2 requests / minute)
- GET endpoints on posts, x =  60 within the default limit window. (60 requests / 15sec)
- for all the other endpoints we use the  default configuration (15 requests / 15sec).

5 - Care must be taken to implement well written and that scales gracefully.


You should not spend more than a day for this exercice, if you do jsut commit your wok in progress and I will review the work done. If necessary, you can add an explanation on this readme file about your solution, where you stopped, what is missing or what you could have done better or differently.

Good luck !

Dear Loic,

### My Solution

1 - We need a place to store each user with the number of requests endpoint . We need to increment this count for each request and reset the count to zero after a time period.

2 - I use redis for this data store. Redis stores key value pairs and allows expiry time to be specified for each entry. Redis also comes with an INCR 1 command that ensures that increment operations are atomic.

3 - I will add a new initializer named throttle.rb which configures our Redis client.

```
# config/initializers/throttle.rb

	require "redis"

	redis_conf  = YAML.load(File.join(Rails.root, "config", "redis.yml"))
	REDIS = Redis.new(:host => redis_conf["host"], :port => redis_conf["port"])
```


```
	# config/redis.yml
	host: localhost
	port: 6379
```

4 - I implement method throttle within ApplicationController

```
	def throttle(endpoint_name: :default)
		throttle_info = Rails.application.config_for(:throttle)
		throttle_time_window = throttle_info[:throttle_time_window]
	  throttle_max_requests = throttle_info[:throttle_max_requests]  
	  key = "user:#{current_user.id}_request_#{endpoint_name}"
		begin
	  	count = REDIS.get(key)
	    unless count
	      REDIS.set(key, 0)
	      REDIS.expire(key, throttle_time_window)
	      return true
	    end
	    if count.to_i >= throttle_max_requests
	      render :status => 429, :json => {:message => "You have fired too many requests. Please wait for some time."}
	      return
	    end
	    REDIS.incr(key)
	    true
	  rescue => error
	  	puts error.inspect
	    ### send email or SMS notification to developer group
	    UserNotifier.send_redis_down_email(Rails.application.admin_email)
	  end
	end
```

5 - Throttle config for every endpoint implemented in file config/throttel.yml

```
	creat_post:
	  throttle_time_window: 60 
	  throttle_max_requests: 2 

	get_posts:
	  throttle_time_window: 15  
	  throttle_max_requests: 60  

	default:
	  throttle_time_window: 15
	  throttle_max_requests: 15
```

6 - In every endpoints, i implemented callbacks for checking throtte, example in post controller:

```
	 /v1/posts_controller.rb

	 before_action only: [:create] do
	      throttle(endpoint_name: :create_post)
	    end

	 before_action only: [:index, :show] do
	  throttle(endpoint_name: :get_posts)
	 end
```

### Restrict

1 - We must install redis server support feature:
```
	On Ubuntu:
	$ wget http://redis.googlecode.com/files/redis-2.4.8.tar.gz
	$ tar -zxvf redis-2.4.8.tar.gz
	$ cd redis-2.4.8
	$ make
	$ make install
	$ make test

	On Mac:
	brew install redis
	$ cd ~/Downloads/redis-2.4.14
	$ make test
	$ make
	$ sudo mv src/redis-server /usr/bin
	$ sudo mv src/redis-cli /usr/bin
	$ mkdir ~/.redis
	$ touch ~/.redis/redis.conf

	Run Redis server:
	$ redis-server
```

2 - Must implement error handling when the redis server is down by catch exeption and send email notification to admin group. In the time redis server downed, throttle feature is stopped.

```
	def send_redis_down_email(email)
    @user = user
    mail( :to => @user.email, :subject => )
    mail(:to => email, :subject => "[#{Rails.env}]Redis server down") do |format|
		  format.text do
		    render :text => "Redis server down, please check it !"
		  end
		end
  end
```

3 - I haven't written unit test for this feature yet.

### Improvement:

1 - I want to implement only one callback throttle in Application Controller, it supports checking for all endpoints. But i don't know how to detect every end point request(name and method type is GET, POST or UPDATE) in Application Controller. So i must use callback in every endpoint controller.

2 - If I have more time, i want to implement throttle config in a file.yaml not use redis.


