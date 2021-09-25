create role tenant1 with login password 'tenant1' connection limit 10;
create database tenant1db owner tenant1;
create tablespace tenant1tb
  with (replica_placement='{"num_replicas": 3, "placement_blocks": [
    {"cloud":"docker","region":"tenant1","zone":"tenant1a", "min_num_replicas":3}]}');
revoke all privileges on tablespace pg_default from tenant1;
revoke all privileges on tablespace pg_global from tenant1;
grant all on tablespace tenant1tb to tenant1 with grant option;
alter role tenant1 set default_tablespace = 'tenant1tb';
alter role tenant1 set temp_tablespaces = 'tenant1tb';