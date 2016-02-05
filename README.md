# Sample-Stream-Service

Reference implementation of a daemon and REST service using RealSelf's [`stream-ruby`](https://github.com/RealSelf/stream-ruby/wiki) gem.

#### Sample Daemon
The daemon includes examples for building a social newsfeed, asynchronous "fanout-on-write" activity distribution, retrying activity handling on failure, custom error handling, and replaying failed messages from an error queue.

#### Sample REST Serive
The REST service includes routes for managing a social graph of "follow" relationships, paged retrieval of a newsfeed, managing a per-user count of unread newsfeed items and synchronous ingestion and fanout of new activities.

# Installation

    git clone git@github.com:RealSelf/sample-stream-service.git
    cd sample-stream-service
    bundle install

# Usage

You need to connect to a running rabbitmq and mongodb servers.  Run one locally, or add environment variables pointing at each.

### Starting the Daemon
    export MONGODB_HOST='localhost:27017'
    export RABBITMQ_URL='amqp://guest:guest@localhost:5672'
    bundle exec bin/sample-daemon

### Starting the REST Service
    export MONGODB_HOST='localhost:27017'
    export RABBITMQ_URL='amqp://guest:guest@localhost:5672'
    bundle exec rackup bin/rest-service
