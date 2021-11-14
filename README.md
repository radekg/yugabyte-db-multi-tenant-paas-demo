## Build the image

- `make docker-image-uid`: builds a Docker image using a downloaded YugabyteDB distribution; this Docker image supports configurable uid/gid
- `make docker-image-postgis`: builds a Docker image using a downloaded YugabyteDB distribution and configures PostGIS; this Docker image supports configurable uid/gid
- `make docker-image-upstream`: builds a Docker image using an upstream image; this Docker image does not support configurable uid/gid

### Build the tools only image

```sh
make docker-image-tools
```

## YugabyteDB dashboard

YugabyteDB dashboard can be accessed on port `7000`. Usually `http://localhost:7000`.

## Monitoring

This Docker Compose configuration comes with Grafana and Prometheus. Prometheus cannot be be accessed directly, Grafana can be accessed on port `3000`, usually `http://localhost:3000`. Grafana instance does not reconfigure the default admin password. Grafana password must to be changed on every container restart.

If you _really, really_ want to change the _admin_ user password, change the _./etc/grafana/grafana.ini_ _admin\_password_ value to something else than the default. **Do not commit the changes to version control!**

Grafana instance comes with the Prometheus _YBPrometheus_ datasource.

## Prereqs

```sh
export DC_ENV_FILE=.env
```

## All in one infrastructure

All in one setup starts all components. There are fifteen containers in this configuration.

### Start all in one

```sh
docker-compose --env-file "$(pwd)/${DC_ENV_FILE}" \
    -f compose-masters.yml \
    -f compose-monitoring.yml \
    -f compose-tservers-shared.yml \
    -f compose-tservers-tenant1.yml \
    -f compose-tservers-tenant2.yml \
    -f compose-tservers-tenant3.yml \
    up
```

Wait for the log output to calm down and initialize tenants. Run these commands in another terminal:

```sh
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" \
    -f sql-init-tenant1.sql
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" \
    -f sql-init-tenant2.sql
```

Followed by creating Northwind ojects in the _tenant1db_ as _tenant1_:

```sh
psql "host=localhost port=35433 dbname=tenant1db user=tenant1" \
    -f sql-init-northwind-tenant1.sql
psql "host=localhost port=35433 dbname=tenant1db user=tenant1" \
    -f sql-init-northwind-data-tenant1.sql
```

Connect as a tenant:

- `tenant 1`: `psql "host=localhost port=35433 dbname=tenant1db user=tenant1"`
- `tenant 2`: `psql "host=localhost port=35434 dbname=tenant2db user=tenant2"`
- `tenant 3`: `psql "host=localhost port=35434 dbname=tenant3db user=tenant3"`

Optionally, connect to _shared_ TServers:

- `psql "host=localhost port=35432 dbname=yugabyte user=yugabyte"`

### Clean everything up

Remove containers:

```sh
docker-compose \
    -f compose-masters.yml \
    -f compose-monitoring.yml \
    -f compose-tservers-shared.yml \
    -f compose-tservers-tenant1.yml \
    -f compose-tservers-tenant2.yml \
    -f compose-tservers-tenant3.yml \
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
    vol_yb_tenant3_1 \
    vol_yb_tenant3_2 \
    vol_yb_tenant3_3 \
    vol_yb_shared_1 \
    vol_yb_shared_2 \
    vol_yb_shared_3
```

## Decommission a tenant

This scenario assumes that that a tenant is going to be decommissioned from the platform. All tenant data will be removed. It is assumed that backups have been taken, if they are required. The tenant may be optionally restored but this will involve restoring tenant data from backups, thus recreacting the infrastructure as it would have been done during the initial onboarding.

The core infrastructure is assumed to be:

```sh
docker-compose --env-file "$(pwd)/${DC_ENV_FILE}" \
    -f compose-masters.yml \
    -f compose-monitoring.yml \
    -f compose-tservers-shared.yml \
    up
```

In another terminal, start tenant 1 TServers:

```sh
docker-compose --env-file "$(pwd)/${DC_ENV_FILE}" \
    -f compose-tservers-tenant1.yml \
    up
```

**Optionally**, start tenant 2 TServers in yet one more terminal:

```sh
docker-compose --env-file "$(pwd)/${DC_ENV_FILE}" \
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

Place TServers in the blacklist. This will prevent the remote bootstrap subsystem from further communication with TServers which we want to remove.

```sh
./tenant1-blacklist.sh
```

Once the blacklist has been updated, wait for `Active Tablet-Peers` for these TServers to come down to `0`. Stop containers with `CTRL+C` in the relevant terminal. Next, remove the containers:

```sh
docker-compose -f compose-tservers-tenant1.yml rm
```

Remove volumes:

```sh
docker volume rm \
    vol_yb_tenant1_1 \
    vol_yb_tenant1_2 \
    vol_yb_tenant1_3
```

### Bring tenant 1 TServers back online

If the tenant is to be re-onboarded, start TServers again:

```sh
docker-compose --env-file "$(pwd)/${DC_ENV_FILE}" -f compose-tservers-tenant1.yml up
```

These TServers are still in the blacklist so they need to be relisted. Remove them from the blacklist:

```sh
./tenant1-whitelist.sh
```

The cluster will take some time to reconcile. When finished, tenant can be reinitialized and relevant backups can be restored.

## Ops

```sh
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_all_masters'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_all_tablet_servers'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 get_load_move_completion'
```

List tablets on a tablet server:

```sh
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_tablets_for_tablet_server ...'
```

```sh
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 modify_placement_info docker.base1.base1a 3'
```