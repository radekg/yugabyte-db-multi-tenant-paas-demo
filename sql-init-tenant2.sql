create role tenant2 with login password 'tenant2' connection limit 10;
create database tenant2db owner tenant2;
create tablespace tenant2tb
  with (replica_placement='{"num_replicas": 3, "placement_blocks": [
    {"cloud":"docker","region":"tenant2","zone":"tenant2a", "min_num_replicas":3}]}');
revoke all privileges on tablespace pg_default from tenant2;
revoke all privileges on tablespace pg_global from tenant2;
grant all on tablespace tenant2tb to tenant2 with grant option;
alter role tenant2 set default_tablespace = 'tenant2tb';
alter role tenant2 set temp_tablespaces = 'tenant2tb';
\connect tenant2db
create extension if not exists dsh;
