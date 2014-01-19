RedmineCRM
==========

Easy update mirror for RedmineCRM

Requirements
------------

- Redmine `>= 2.1.0`


Installation
------------

- Clone this repository
- Install dependencies and migrate database:

        cd redmine/
        git init
        git remote add origin https://github.com/sergeyz/RedmineCRM.git
        git fetch
        git checkout -t origin/master
        bundle install --without development test
        bundle exec rake redmine:plugins RAILS_ENV=production

- Restart your Redmine web server
