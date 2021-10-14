#!/bin/bash
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant2-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant2-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_leader_blacklist ADD yb-tserver-tenant2-3:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant2-1:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant2-2:9100'
docker exec -ti yb-master-n1 /bin/bash -c \
    'yb-admin -master_addresses yb-master-n1:7100,yb-master-n2:7100,yb-master-n3:7100 change_blacklist ADD yb-tserver-tenant2-3:9100'
