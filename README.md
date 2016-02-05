# Sample-Stream-Service

Herein this fair repository lies our intentions, be they good or bad, right or wrong, noble or nefarious.  Our
sanguine goal is to show that Sneakers is a viable, _nay_, __desireable__ platform upon which to found our new __Service Empire__.  Our successes will be heard around the solar system as shockwaves of triumph coursing through the nether regions of planets, asteroids, and little varmints skittering who-knows-where.

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
