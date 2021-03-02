-- # In AWS console, go to RDS instance / Connectivity and change master password (on db instance, modify, tick 'apply immediatedly', save).
-- # Get endpoint and update the one below in the psql command.

-- # login to db jumpbox (check that sg_jumpbox allows ingress on port 22 for your jumpbox ip, e.g. 54.239.6.185/32)
-- ssh ec2-user@<public ip address of ec2 instance>

-- # connect to db server (you do not have to be root on the jump box), use the AWS RDS endpoint
-- psql \
   --host=tfaurora-example-1.cbnlfy36tjpq.eu-central-1.rds.amazonaws.com \
   --port=5432 \
   --username=root \
   --password \
   --dbname=postgres

-- psql \
   --host=tfaurora2-example-1.cbnlfy36tjpq.eu-central-1.rds.amazonaws.com \
   --port=5432 \
   --username=root \
   --password \
   --dbname=postgres

-- create a new db 'mydb1' and list all databases to show that it has been created
CREATE DATABASE mydb1;
SELECT datname FROM pg_database;
\l

-- connect to 'mydb1'
\c mydb1

-- create a schema (i.e. db namespace) and a table and insert a row
CREATE SCHEMA myschema
   CREATE TABLE mytable(
      id INT PRIMARY KEY, 
      name VARCHAR(20) NOT NULL
   );

-- server 1 only
INSERT INTO myschema.mytable VALUES (1, 'Smith');

-- check table content
SELECT * FROM myschema.mytable;

-- server 2 only
TRUNCATE myschema.mytable;

-- check table content
SELECT * FROM myschema.mytable;

-- list all non-system tables
SELECT *
FROM pg_catalog.pg_tables
WHERE schemaname != 'pg_catalog' AND 
    schemaname != 'information_schema';

-- delete schema 'myschema' and all its dependent objects (tables, functions, triggers, views etc.)
DROP SCHEMA myschema CASCADE;

-- connect back to PostgreSQL system database and delete 'mydb1' (deletion of a database works only if you are not connected to it)
\c postgres
DROP DATABASE mydb1;

-- disconnect from db server
\q

-- # disconnect from jump box
-- exit
