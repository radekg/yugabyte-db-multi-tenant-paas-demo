## Build the image

This step is required for the image to properly handle stop signals.

```cd
cd ./.docker/yugabyte-db
docker build -t local/yugabyte:2.9.0.0-b4 .
cd -
```

## Start the infrastructure

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

## YugabyteDB dashboard

YugabyteDB dashboard can be accessed on port `7000`. Usually `http://localhost:7000`.

## Monitoring

This Docker compose configuration comes with Grafana and Prometheus. Prometheus cannot be be accessed directly, Grafana can be accessed on port `3000`, usually `http://localhost:3000`. Grafana instance does not reconfigure the default admin password. Grafana password must to be changed on every container restart.

If you really, really want to change the _admin_ user password, change the _./etc/grafana/grafana.ini_ _admin\_password_ value to something else than the default but please do not commit the changes to version control!

Grafana instance comes with the Prometheus _YBPrometheus_ datasource configured.

## Init tenants

```
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" -f sql-init-tenant1.sql
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" -f sql-init-tenant2.sql
```

## Initialize Northwind as tenant 1

```
psql "host=localhost port=35432 dbname=tenant1db user=tenant1" -f sql-init-northwind-tenant1.sql
psql "host=localhost port=35432 dbname=tenant1db user=tenant1" -f sql-init-northwind-data-tenant1.sql
```

## Connect as tenants

```
psql "host=localhost port=35432 dbname=tenant1db user=tenant1"
```

```
psql "host=localhost port=35432 dbname=tenant2db user=tenant2"
```

## Ops

```
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_all_masters'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_all_tablet_servers'
```

List tablets on a tablet server:

```
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 list_tablets_for_tablet_server ...'
```

## Clean everything up

```sh
docker-compose \
    -f compose-lb.yml \
    -f compose-masters.yml \
    -f compose-monitoring.yml \
    -f compose-tservers-shared.yml \
    -f compose-tservers-tenant1.yml \
    -f compose-tservers-tenant2.yml \
    rm
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

## Decommission tenant 1 TServers

First, start the minimum setup with tenant1 TServers:

```
docker-compose \
    -f compose-lb.yml \
    -f compose-masters.yml \
    -f compose-monitoring.yml \
    -f compose-tservers-shared.yml \
    up
```

In another terminal, start tenant 1 TServers:

```
docker-compose \
    -f compose-tservers-tenant1.yml \
    up
```

Optionally, start tenant 2 TServers in yet one more terminal:

```
docker-compose \
    -f compose-tservers-tenant2.yml \
    up
```

### Remove all data of tenant 1

```
psql "host=localhost port=35432 dbname=yugabyte user=yugabyte" -f sql-wipe-tenant1.sql
```

```
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant1-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant1-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant1-3:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant1-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant1-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant1-3:9100'
```

```
docker-compose -f compose-tservers-tenant1.yml rm
```

```
docker volume rm \
    vol_yb_tenant1_1 \
    vol_yb_tenant1_2 \
    vol_yb_tenant1_3
```

### Bring tenant 1 TServers back online

```
docker-compose -f compose-tservers-tenant1.yml up
```

```
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist REMOVE yb-tserver-tenant1-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist REMOVE yb-tserver-tenant1-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist REMOVE yb-tserver-tenant1-3:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist REMOVE yb-tserver-tenant1-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist REMOVE yb-tserver-tenant1-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c 'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist REMOVE yb-tserver-tenant1-3:9100'
```
