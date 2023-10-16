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

## Uninstall

```
helm uninstall \
  -n pwpush \
  my-passwordpush
```
