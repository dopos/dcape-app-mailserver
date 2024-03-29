# dcape-app-mailserver

[![GitHub Release][1]][2] [![GitHub code size in bytes][3]]() [![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape-app-mailserver.svg
[2]: https://github.com/dopos/dcape-app-mailserver/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape-app-mailserver.svg
[4]: https://img.shields.io/github/license/dopos/dcape-app-mailserver.svg
[5]: LICENSE

Mail server application package for [dcape](https://github.com/dopos/dcape).

## Docker image used

* [docker-mailserver](https://github.com/docker-mailserver/docker-mailserver)

## Requirements

* linux 64bit (git, make, wget, gawk, openssl)
* [docker](http://docker.io)
* [dcape](https://github.com/dopos/dcape)
* Git service ([github](https://github.com), [gitea](https://gitea.io) or [gogs](https://gogs.io))

## Install

* Fork this repo in your Git service
* Setup deploy hook
* Run "Test delivery" (config sample will be created in dcape)
* Edit and save config (enable deploy etc)
* Run "Test delivery" again (app will be installed and started on webhook host)
* Fork [dopos/dcape-dns-config](https://github/com/dopos/dcape-dns-config) and cook your zones

See also: [Deploy setup](https://github.com/dopos/dcape/blob/master/DEPLOY.md) (in Russian)

## Usage

### Add user

```
sudo make user-add USER_EMAIL=user@domain USER_PASS=<password>
```

### Setup DKIM

```
sudo make dkim-add
```

### Disable amavis quarantine

Add config/amavis.cf:
```
$final_spam_destiny=D_PASS;
$final_virus_destiny=D_PASS;

1;
```
See also: [how to disable quarantine](https://serverfault.com/a/801054)

### Letsencrypt

Based on [traefik v2](https://docker-mailserver.github.io/docker-mailserver/latest/config/security/ssl/#traefik-v2)

## License

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2017 Alexey Kovrizhkin <lekovr+dopos@gmail.com>
