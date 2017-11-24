# ManagedWP

Managing WordPress installations that only use free plugins and themes is painful. ManagedWP allows you to use Composer for plugin and theme dependency management and provides scripts to deploy updated with a simple shell command.

This is a stripped-down version of [WordPressBP](https://github.com/andrejcremoznik/WordPressBP).


## System requirements

* LEMP stack (Linux, Nginx, PHP 5.6+, MySQL)
* NodeJS (`node`, `npm`)
* [Composer](https://getcomposer.org/)
* [WP-CLI](http://wp-cli.org/)

Read [this Gist](https://gist.github.com/andrejcremoznik/07429341fff4f318c5dd) on how to correctly set these tools up on your development environment.


## Instructions

1. Clone this repository and move into it
2. Run the setup script
  ```
  $ ./setup.sh
  Usage:
  ./setup.sh <namespace> <project_path> [<branch>]

  Params:
    <namespace>:    Lowercase alphanumeric name for your project. Must not start with a number. Must be directory / file system / URL friendly.
    <project_path>: Absolute path to directory where the project structure will be set up.
    <branch>:       Branch from which to create the project structure. Defaults to 'master'.

  Example:
    ./setup.sh mything /srv/http/mything.dev
  ```
3. Configure web server (Nginx example below)
4. Map the IP of the development machine to `mything.dev` in your hosts (`/etc/hosts`).
5. Login at `http://mything.dev/wp/wp-login.php` (login: dev / dev)


### Example Nginx configuration

For development:

```
server {
  listen [::]:80 deferred;
  listen 80 deferred;

  server_name ManagedWP.dev;
  root /srv/http/ManagedWP.dev/web;

  access_log off;

  # Rewrite URLs for uploaded files from dev to prod
  # - If you've synced the DB from a production site, you don't need to
  #   download the uploads folder for images to work
  #location /app/uploads {
  #  rewrite ^ http://production.site/$request_uri permanent;
  #}

  location / {
    try_files $uri $uri/ @wordpress;
  }

  location @wordpress {
    rewrite ^ /index.php last;
  }

  location ~ \.php$ {
    try_files $uri =404;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_pass unix:/var/run/php/php7.1-fpm.sock;
  }
}
```

* [Complete production configuration](https://gist.github.com/andrejcremoznik/13ceca9d83abb3088353066b240138d5)
* [Complete production configuration with SSL](https://gist.github.com/andrejcremoznik/f0036b58398cafaa9b14ff04030646da)


## Adding free plugins and themes

If you don't know Composer, read the [introduction](https://getcomposer.org/doc/00-intro.md) first.

Plugins and themes hosted on https://wordpress.org/ are available through [WordPress Packagist](https://wpackagist.org/).
You can also use any public git repository on the internet with composer.

* Install plugins with: `composer require wpackagist-plugin/akismet`.
* Install themes with: `composer require wpackagist-theme/white-spektrum`
* Keep them up-to-date with `composer update`


## Adding proprietary plugins and themes

You want to keep those out of the repository but still deploy them with the rest of the code. `.gitignore` is set up to ignore everything inside `web/app/{themes,plugins}/` so you can easily place your themes and plugin there for local development.

Then open `config/scripts/deploy-pack.js` and make sure these files are copied into the `build` directory before deploy. To do that look for the `TODO` comment near the top of the file for examples.


## Deploying

Please read the section on [deploying WordPressBP](https://github.com/andrejcremoznik/WordPressBP#deploying).

ManagedWP works the same except that default environment is `production`.


## Syncing database from production

1. Have a look at the `sync.sh` script and set it up
2. Run it `./sync.sh`


## Setting up a fresh environment

1. Clone your repo
2. Prepare the database
3. Copy `.env.example` to `.env` and set it up
4. Run `./sync.sh`
5. Set up the web server and hosts file
