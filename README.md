# proxy 🚦

A reverse proxy on Docker to handle connection requests for various apps, that use the same port numbers, hosted on my local machine.

## Instructions

For the application's service in its `compose.yaml` file:

1. "Unexpose" port(s) from the service.
1. Set `networks` to `proxy`.
1. Set `hostname` to the desired hostname (e.g. `my-app.local`).
1. Add the following labels:

    ```sh
    - "traefik.enable=true"
    - "traefik.http.routers.<UNIQUE_KEY>.entrypoints=<ENTRYPOINT>"
    - "traefik.http.routers.<UNIQUE_KEY>.rule=Host(`<HOSTNAME>`)"
    - "traefik.http.routers.<UNIQUE_KEY>.service=<UNQIUE_KEY>"
    - "traefik.http.services.<UNIQUE_KEY>.loadbalancer.server.port=<PORT>"
    ```

1. Add this to `networks`:

    ```sh
    networks:
        proxy:
            external: true
    ```

In this proxy's `compose.yaml` file, make the following updates if necessary:

1. Add an entrypoint and labels for the port number(s) if they do not already exist.
1. Expose the port(s) if not already done.

Add the hostname (e.g. `my-app.local`) to `/etc/hosts`.

Start up.

```sh
make
```

Or recreate.

```sh
make restart
```

## Dashboard

See: [http://proxy.local:8080/dashboard](http://proxy.local/dashboard).

`proxy.local` should be in `/etc/hosts`.

```sh
make dashboard
```

## Current Usage

- [tifa/art](http://github.com/tifa/art) - scribbles
- [tifa/color-chart](http://github.com/tifa/color-chart) - digital color mixing chart
- [tifa/meijung](http://github.com/tifa/meijung) - travel log
- [tifa/post](http://github.com/tifa/post) - posts
- [tifa/tree](http://github.com/tifa/tree) - family geneaology site
