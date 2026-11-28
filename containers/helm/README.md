# Helm

A basic Helm deploy of Password Push

## Quickstart

Requires Helm 3+

```
helm install
  --create-namespace \
  --namespace pwpush \
  my-passwordpusher \
  .
```

Where `.` is the path to this `helm` directory. This will create a basic deployment and service, which you can forward to your local machine by running:

```
kubectl port-forward --namespace pwpush svc/my-passwordpusher-helm 5555:5100
```

and then opening up your browser to [localhost:5555](http://localhost:5555).

## Update notice channel

The chart default `image.tag` is `stable`. The pod gets `PWP__RELEASE_CHANNEL` derived from that tag (`stable` → `stable`, anything else → `latest`) so the admin update notice matches the image.

Override with `releaseChannel: latest` (or `stable`), or set `env.PWP__RELEASE_CHANNEL`, which always wins.

## Uninstall

```
helm uninstall \
  -n pwpush \
  my-passwordpush
```
