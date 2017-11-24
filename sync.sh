#!/bin/bash

#
# This script will:
# 1. check if WP-CLI is available locally and on server
# 2. empty your local database (NO BACKUP! If you need a backup, extend this script.)
# 3. connect to server, using WP-CLI dump the database, pipe compressed data locally, uncompress and import using WP-CLI
# 4. deactivate specified plugins
# 5. delete revisions, cache and transients
# 6. perform a search-replace for site URL and flush rewrite rules
# 7. create an admin user for development (dev / dev)
#
# TODO: Review below TODOs to setup the script
#

# TODO: Setup SSH connection parameters
ssh_connection="user@ManagedWP -p 22"
remote_wordpress="/srv/http/ManagedWP/releases/current/web/wp"

function findWPCLI {
  command -v wp > /dev/null 2>&1 || { echo >&2 "==> WP-CLI needs to be available as 'wp' command in your PATH $1"; exit 1; }
}
findWPCLI locally
ssh $ssh_connection "$(typeset -f); findWPCLI 'on server'" || exit 1;

echo "==> Dropping local database…"
wp db reset --yes

echo "==> Importing database from production…"
ssh $ssh_connection "wp --path=$remote_wordpress db export - | gzip" | gunzip | wp db import -

# TODO: You can deactivate plugins you don't want locally
#echo "==> Disabling production only plugins…"
#wp plugin deactivate wordpress-seo

echo "==> Removing spam…"
wp comment delete $(wp comment list --status=spam --format=ids) --force

echo "==> Cleaning up cache and stuff…"
wp db query "DELETE FROM wpdb_posts WHERE post_type = 'revision'"
wp cache flush
wp transient delete-all

# TODO: Replace production domain with dev domain
#echo "==> Search/replace hostname…"
#wp search-replace ManagedWP.tld ManagedWP.dev

echo "==> Flushing rewrite rules…"
wp rewrite flush

echo "==> Optimizing database…"
wp db optimize

echo "==> Creating admin account for development (login: dev / dev)"
wp user create dev dev@dev.dev --user_pass=dev --role=administrator

echo "==> Done."
