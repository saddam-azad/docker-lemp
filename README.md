<p align="center">
  <a href="https://github.com/cloudbitsio/lightbulb-alpine"><img width="240" src="lightbulb.svg"></a>
</p>
<p>Docker container with NGINX and PHP.</p>
<p align="center">
  <img src="https://img.shields.io/docker/v/cloudbitsio/lightbulb-alpine?color=999&sort=semver">
  <img src="https://img.shields.io/docker/image-size/cloudbitsio/lightbulb-alpine?color=999&sort=semver">
  <img src="https://img.shields.io/docker/pulls/cloudbitsio/lightbulb-alpine?color=999&sort=semver">
</p>
<p align="center">
  <a href="#docker-lemp">About</a> |
  <a href="#features">Features</a>
</p>

---

# Docker LEMP 

The Lightbulb project consists of a Docker container with hardened NGINX and PHP upon Alpine Linux. Lightweight, performant and secure.

Licensed under [MIT](./LICENSE).

## Features

- The NGINX server is compiled with the latest [NAXSI WAF](https://github.com/nbs-system/naxsi) and [Cache Purge](https://github.com/FRiCKLE/ngx_cache_purge/) modules.
- PHP extensions are managed with the excellent [Docker PHP Extension Installer](https://github.com/mlocati/docker-php-extension-installer).
- Lightbulb utlizes [Filament](https://github.com/cloudbitsio/filament) as the drop-in replacement for /etc/nginx.