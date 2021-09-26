## Build the image

This step is required for the image to properly handle stop signals.

```sh
cd ./.docker/yugabyte-db
docker build -t local/yugabyte:2.9.0.0-b4 .
cd -
```

## YugabyteDB dashboard

YugabyteDB dashboard can be accessed on port `7000`. Usually `http://localhost:7000`.

## Monitoring

This Docker compose configuration comes with Grafana and Prometheus. Prometheus cannot be be accessed directly, Grafana can be accessed on port `3000`, usually `http://localhost:3000`. Grafana instance does not reconfigure the default admin password. Grafana password must to be changed on every container restart.

If you really, really want to change the _admin_ user password, change the _./etc/grafana/grafana.ini_ _admin\_password_ value to something else than the default but please do not commit the changes to version control!

Grafana instance comes with the Prometheus _YBPrometheus_ datasource configured.

## All in one infrastructure

```sh
docker-compose \
    -f compose-lb.yml \
    -f compose-masters.yml \
    -f compose-monitoring.yml \
    -f compose-tservers-shared.yml \
    -f compose-tservers-tenant1.yml \
    -f compose-tservers-tenant2.yml \
    up
```

Initialize tenants, in another terminal:

```sh
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" \
    -f sql-init-tenant1.sql
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" \
    -f sql-init-tenant2.sql
```

Followed by creating Northwind ojects in the _tenant1db_:

```sh
psql "host=localhost port=35432 dbname=tenant1db user=tenant1" \
    -f sql-init-northwind-tenant1.sql
psql "host=localhost port=35432 dbname=tenant1db user=tenant1" \
    -f sql-init-northwind-data-tenant1.sql
```

To connect as a tenant:

- `tenant 1`: `psql "host=localhost port=35432 dbname=tenant1db user=tenant1"`
- `tenant 2`: `psql "host=localhost port=35432 dbname=tenant2db user=tenant2"`

## Ops

```sh
docker exec -ti yb-master-n1 /bin/bash -c \
        'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_all_masters'
docker exec -ti yb-master-n1 /bin/bash -c \
        'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_all_tablet_servers'
```

List tablets on a tablet server:

```sh
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_tablets_for_tablet_server ...'
```

### Clean everything up

Remove containers:

```sh
docker-compose \
    -f compose-lb.yml \
    -f compose-masters.yml \
    -f compose-monitoring.yml \
    -f compose-tservers-shared.yml \
    -f compose-tservers-tenant1.yml \
    -f compose-tservers-tenant2.yml \
    rm
```

Remove volumes:

```sh
docker volume rm \
    vol_yb_master_1 \
    vol_yb_master_2 \
    vol_yb_master_3 \
    vol_yb_tenant1_1 \
    vol_yb_tenant1_2 \
    vol_yb_tenant1_3 \
    vol_yb_tenant2_1 \
    vol_yb_tenant2_2 \
    vol_yb_tenant2_3 \
    vol_yb_shared_1 \
    vol_yb_shared_2 \
    vol_yb_shared_3
```

## Decommission a tenant

This scenario assumes that that a tenant is going to be decommissioned from the platform. All tenant data will be removed. It is assumed that backups have been taken, if they are required. The tenant may be optionally restored but this will involve restoring tenant data from backups, thus recreacting the infrastructure as it would have been done during the initial onboarding.

The core infrastructure is assumed to be:

```sh
docker-compose \
    -f compose-lb.yml \
    -f compose-masters.yml \
    -f compose-monitoring.yml \
    -f compose-tservers-shared.yml \
    up
```

In another terminal, start tenant 1 TServers:

```sh
docker-compose \
    -f compose-tservers-tenant1.yml \
    up
```

**Optionally**, start tenant 2 TServers in yet one more terminal:

```sh
docker-compose \
    -f compose-tservers-tenant2.yml \
    up
```

Onboard tenant 1:

```sh
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" \
    -f sql-init-tenant1.sql
psql "host=localhost port=35432 dbname=tenant1db user=tenant1" \
    -f sql-init-northwind-tenant1.sql
psql "host=localhost port=35432 dbname=tenant1db user=tenant1" \
    -f sql-init-northwind-data-tenant1.sql
```

### Remove all data of tenant 1

Once tenant is onboarded, boot him out of the platform. **The order is important.** First, remove all tenant data from the database, maybe backups had to be taken, if so, they were taken.

```sh
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" -f sql-wipe-tenant1.sql
```

Place the TServers in the blacklist. This will prevent the remote bootstrap subsystem from further communication with the TServers which we want to remove.

```sh
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant1-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant1-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant1-3:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant1-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant1-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant1-3:9100'
```

Once the blacklist has been updated, wait for `Active Tablet-Peers` for these TServers to come down to `0`. Stop the containers with `CTRL+C` in the relevant terminal. Next, remove the containers:

```sh
docker-compose -f compose-tservers-tenant1.yml rm
```

And remove volumes:

```sh
docker volume rm \
    vol_yb_tenant1_1 \
    vol_yb_tenant1_2 \
    vol_yb_tenant1_3
```

### Bring tenant 1 TServers back online

If the tenant is to be re-onboarded, start the relevant TServers again:

```sh
docker-compose -f compose-tservers-tenant1.yml up
```

These TServers are still in the balcklist, they need to be removed from the blacklist.

```sh
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist REMOVE yb-tserver-tenant1-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist REMOVE yb-tserver-tenant1-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist REMOVE yb-tserver-tenant1-3:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist REMOVE yb-tserver-tenant1-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist REMOVE yb-tserver-tenant1-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist REMOVE yb-tserver-tenant1-3:9100'
```

The cluster will take some time to reconcile. When finished, tenant can be reinitialized and relevant backups can be restored.
