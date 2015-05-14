# Sample-Daemon

Herein this fair repository lies our intentions, be they good or bad, right or wrong, noble or nefarious.  Our
sanguine goal is to show that Sneakers is a viable, _nay_, __desireable__ platform upon which to found our new __Daemon Empire__.  Our successes will be heard around the solar system as shockwaves of triumph coursing through the nether regions of planets, asteroids, and little varmints skittering who-knows-where.

# Installation

    git clone git@github.com:RealSelf/sample-daemon.git
    cd sample-daemon
    bundle install

# Usage

You need to connect to a running rabbitmq-server.  Run one locally, or add a RABBITMQ_URL environment variable pointing at a real rabbitmq server.  URL format must be of the form: `amqp://guest:guest@localhost:5672`.

    bundle exec foreman start
