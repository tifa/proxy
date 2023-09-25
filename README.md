# proxy 🚦

A Traefik reverse proxy on Docker to handle connection requests for various apps.

## Setup

Copy the sample environment file.

```sh
cp .env.example .env
```

Valid values for the `ENVIRONMENT` variable are `local` and `prod`. The local environment uses self-signed SSL certificates for HTTPS connections whereas in production it uses [Let's Encrypt][lets-encrypt].

Update `HOSTNAMES` with a comma-separated list of domain names to create certificates for, e.g. `*.tifa.local`, `tifa.io`, `localhost`.

Start up the Docker network and reverse proxy container.

```sh
make start
```

In development environments, a certificate will be created at `./assets/traefik/certs/local.crt`. Make sure you add this to the list of trusted SSL certificates ([macOS steps][trust-certificate-macos]).

To view the Traefik dashboard:

```sh
make open
```

## Add a New Service

Add the following labels and `proxy` network to service:

```yaml
  myservice:
    image: myimage
    labels:
      traefik.enable: true
      traefik.http.routers.<ROUTER_KEY>.rule: Host(`${HOSTNAME:-}`)
      traefik.http.routers.<ROUTER_KEY>.entrypoints: <ENTRYPOINT>
    networks:
      - proxy
```

Each service needs to have a unique `ROUTER_KEY`/`SERVICE_KEY`.

Currently supported entrypoints:

Entrypoint | Port
--- | ---
web | 80
websecure | 443
mysql | 3306

For `websecure` HTTPS connections be sure to enable TLS as well.

```yaml
    traefik.http.routers.<ROUTER_KEY>.tls.certresolver: letsencrypt
```

Finally, define the external network at the top level.

```yaml
networks:
  proxy:
    external: true
```

## Add a New Domain

Update the `.env` file with the new domain name.

For local environments,  (and add it to your trusted certificates list):

```sh
make start
```


<!-- docs -->
[trust-certificate-macos]: docs/trust-certificate-macos.md

<!-- external -->
[lets-encrypt]: https://letsencrypt.org
