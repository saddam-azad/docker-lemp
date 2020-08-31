#!/bin/bash

## -x Print commands and their arguments as they are executed.
#  http://linuxcommand.org/lc3_man_pages/seth.html
set -x

## Run Nginx and PHP7.4-FPM
#
nginx -g "daemon off;"
php-fpm7 --nodaemonize