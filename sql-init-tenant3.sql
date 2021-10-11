create role tenant3 with login password 'tenant3' connection limit 10;
create database tenant3db owner tenant3;
create tablespace tenant3tb
  with (replica_placement='{"num_replicas": 3, "placement_blocks": [
    {"cloud":"docker","region":"tenant3","zone":"tenant3a", "min_num_replicas":3}]}');
revoke all privileges on tablespace pg_default from tenant3;
revoke all privileges on tablespace pg_global from tenant3;
grant all on tablespace tenant3tb to tenant3 with grant option;
alter role tenant3 set default_tablespace = 'tenant3tb';
alter role tenant3 set temp_tablespaces = 'tenant3tb';
\connect tenant3db
create extension if not exists dsh;
