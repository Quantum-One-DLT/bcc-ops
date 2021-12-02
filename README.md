# bcc-ops

NixOps deployment configuration for TBCO/Bcc devops. Note that TBCO Hydra server will be live soon.  

For examples on how you can deploy your own testnet please refer to the
[REAME](examples/sophie-testnet/README.md) of the Sophie testnet example.

## Explorer upgrades

The explorer is composed with a traefik frontend (`explorer`) and two backends (`explorer-a` and `explorer-b`). The backends are dedicated machines, unless `globals.explorerBackendsInContainers = true;` in which case the backends are packed together (as containers) with the traefik frontend.

We upgrade one backend after the other to achieve zero-downtime upgrades.

On `testnet` and `mainnet`, after the upgrade is completed, a snapshot of the bcc-db-sync database is done and uploaded to s3 buckets:
 - for `testnet`: `updates-bcc-testnet` (`https://updates-bcc-testnet.s3.amazonaws.com`)
 - for `mainnet`: `update-bcc-mainnet.tbco.io` (`https://update-bcc-mainnet.tbco.io`)


### Process

1. add pins for a set of new versions of explorer services (that work together), eg.:

```sh
niv add The-Blockchain-Company/bcc-db-sync -n bcc-db-sync-10 -b refs/tags/10.0.0
niv add The-Blockchain-Company/bcc-graphql -n bcc-graphql-next -b chore/bcc-db-sync-10-compat
niv add The-Blockchain-Company/bcc-explorer-app -n bcc-explorer-app-next -b chore/bcc-graphql-5.0.0-compat
```

2. Create a set for those new versions in `globals-default.nix`

Set one of backend (`b`) to use this new set (`explorer10`), and keep only the untouched backend in the active set:
```nix
  explorerBackends = {
    # explorer-a is updated to use the new set:
    a = globals.explorer10;
    b = globals.explorer9;
  };

  # explorer-a is being upgraded: we remove it from traefik load-balencer:
  explorerActiveBackends = ["b"];

  # new set of versions (to be updated with final tags before mainnet release)
  explorer10 = {
    bcc-db-sync = sourcePaths.bcc-db-sync-10;
    bcc-explorer-app = sourcePaths.bcc-explorer-app-next;
    bcc-graphql = sourcePaths.bcc-graphql-next;
  };
```

Commit this change to new branch and deploy it (`explorer` on `sophie-qa` or `explorer-a` on `staging`/`testnet`).

If this is a major upgrade, database on `explorer-a` need to be deleted:
`systemctl stop postgresql.service && rm -rf /var/lib/postgresql/12 && systemctl start postgresql.service && systemctl restart bcc-db-sync`.

2. Take a snapshot on explorer-a:

First we need to wait until `bcc-db-sync` is fully synced. Then we modify topology file to include this bit:

```nix
explorer-a.services.bcc-db-sync.takeSnapshot = "once";
```

3. Swith frontend to updated backend (`explorer-a`) and prepare upgrade of `explorer-b`:

Edit `globals-default.nix` so that `explorer-a` use the new version, and the traefik frontend use the new version on `explorer-b`.

```nix
  explorerBackends = {
    a = globals.explorer10;
    # we now update explorer-b:
    b = globals.explorer10;
  };

  # explorer-a is now fully synced and ready to serve requests:
  explorerActiveBackends = ["a"];
```
Deploy frontend:
```sh
$ nixops --include explorer
```
At this point please check explorer web ui and rollback this last change if there is any issue.

4. Upgrade `explorer-b` using the snapshot

```sh
$ nixops ssh explorer-a -- ls /var/lib/cexplorer/*tgz
/var/lib/cexplorer/db-sync-snapshot-schema-10-block-5886057-x86_64.tgz

$ nixops scp --from explorer-a /var/lib/cexplorer/db-sync-snapshot-schema-10-block-5886057-x86_64.tgz ./
$ nixops scp --to explorer-b db-sync-snapshot-schema-10-block-5886057-x86_64.tgz /var/lib/cexplorer/

$ nixops deploy --include explorer-b
```
Then wait for `explorer-b` to be fully synced.

5. Update frontend to use both backend

Edit `globals-default.nix` to activate both backends:

```nix
  explorerBackends = {
    a = globals.explorer10;
    b = globals.explorer10;
  };
  explorerActiveBackends = ["a" "b"];
```
Push this change to the branch and merge it to master.

```sh
$ nixops deploy --include explorer
```

6. Upload snapshot to S3

On testnet:
```
source ../proposal-ui/static/proposal-ui-testnet.sh
./scripts/checksum-sign-upload.sh db-sync-snapshot-schema-10-block-2700107-x86_64.tgz updates-bcc-testnet bcc-db-sync
```

On mainnet:
```
source ../proposal-ui/static/proposal-ui-mainnet.sh
./scripts/checksum-sign-upload.sh db-sync-snapshot-schema-10-block-2700107-x86_64.tgz update-bcc-mainnet.tbco.io bcc-db-sync
```

## Accessing Prometheus ##


It is possible to query [Prometheus instances](https://monitoring.bcc-mainnet.tbco.io/prometheus "bcc-mainnet") directly (rather than via [Grafana](https://monitoring.bcc-mainnet.tbco.io/grafana/ "bcc-mainnet") using the Prometheus [query language](https://prometheus.io/docs/prometheus/latest/querying/basics/), for example

```
bcc_node_metrics_utxoSize_int{hostname="stk-a-1-IOG1-ip"}[5m]
```

For larger queries, replacing `5m` (minutes) by `5d` (days) the GUI is
inconvenient and it is better to use a programming environment to
submit an HTTP request and parse the response. One way to do this is
to use Firefox as described
[here](https://daniel.haxx.se/blog/2015/11/23/copy-as-curl/).

Using this may give you several possible HTTP requests:

![](images/FirefoxDebugExample.png "Obtaining the HTTP request")

Choose the one that corresponds to the required query and then copy as
`cURL` and execute it at the command line. It should also be possible
to use this in a programming language such as Python.

