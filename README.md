RedmineCRM
==========

Easy update mirror for RedmineCRM

Installation
------------

- Init repository

        cd redmine/
        git init
        git remote add origin https://github.com/sergeyz/RedmineCRM.git
        git fetch
        git checkout -t origin/master

- Or get updates

        cd redmine/
        git pull

- Install dependencies and migrate database:

        bundle install --without development test
        bundle exec rake redmine:plugins RAILS_ENV=production

- Restart your Redmine web server


Optional
------------

- Install color patch

        patch --verbose -p1 < colors.diff




