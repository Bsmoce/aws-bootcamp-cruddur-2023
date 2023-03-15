# Week 4 — Postgres and RDS

## Provision RDS Instance

```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username root \
  --master-user-password TreEz2QWa15 \
  --allocated-storage 20 \
  --availability-zone ca-central-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```

To connect to psql via the psql client cli tool remember to use the host flag to specific localhost.

```
psql -Upostgres --host localhost
```

## Create database
We can create the database within the PSQL client


```sql
CREATE database cruddur;
```

## Add UUID Extension

We'll create a new SQL file called `schema.sql` in `backend-flask/db`
Then we are going to have Postgres generate out UUIDs in `schema.sql`

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

```

## Import Script

The command to import:
```
psql cruddur < db/schema.sql -h localhost -U postgres
```

## Connection URL format for psql

```sh
postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]
```
Set Vars

```sh
export CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"

gp env CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"

psql $CONNECTION_URL
```

## Create (and dropping) our database

For things we commonly need to do we can create a new directory called `bin`

We'll create an new folder called `bin` to hold all our bash scripts. <br>

https://www.postgresql.org/docs/current/app-createdb.html <br>


We can use the createdb command to create our database inside `backend-flask/bin/db-create`


```sh
#! /usr/bin/bash

echo "db-create"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "create database cruddur;"
```
> Then we change the file permissions: chmod u+x bin/db-create <br>

We can use the drop database command to delete our database inside `backend-flask/bin/db-drop`

```sh
#! /usr/bin/bash

echo "db-drop"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
```
> Then we change the file permissions: chmod u+x bin/db-drop <br>

We can use this file `db-schema-load` to load the scheme

```sh
#! /usr/bin/bash

echo "db-schema-load"
schema_path="$(realpath .)/db/schema.sql"

echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path

```
> Then we change the file permissions: chmod u+x bin/db-schema-load <br>

## Make prints nicer

We we can make prints for our shell scripts coloured so we can see what we're doing:

https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux


```sh
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"
```

## Create our tables

https://www.postgresql.org/docs/current/sql-createtable.html<br>
Inside `backend-flask/db/schema.sql`

```sql
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;
```

```sql
CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text,
  handle text,
  cognito_user_id text,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```

```sql
CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```

then run the command:
```sh
./bin/db-schema-load
```

We'll create a new bash script `backend-flask/bin/db-connect`

```sh
#! /usr/bin/bash

psql $CONNECTION_URL
```
## Shell script to load the seed data

We'll create a new bash script `backend-flask/bin/db-seed`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"
echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```

## Mock data
We create new file `backend-flask/db/seed.sql`

```sql
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```
> Then we change the file permissions: chmod u+x db/seed.sql <br>

![Postgres](assets/Week04-PSQL.png)<br>

## See what connections we are using

We create new file `/backend-flask/bin/db-sessions`

```sh
NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```

## Easily setup (reset) everything for our database

We create new file `/backend-flask/bin/db-setup`

```sh
#! /usr/bin/bash
-e # stop if it fails at any point

#echo "==== db-setup"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```
> Then we change the file permissions: chmod u+x bin/db-setup <br>


## Install Postgres Client

We'll add the following to our `requirments.txt`

```
psycopg[binary]
psycopg[pool]
```
```sh
pip install -r requirements.txt
```

We need to set the env var for our backend-flask application `docker-compose.yml`:

```yml
  backend-flask:
    environment:
      CONNECTION_URL: "${CONNECTION_URL}"
```


## DB Object and Connection Pool


`lib/db.py`

```py
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

In our `backend-flask/services/home_activities.py` we'll replace our mock endpoint with real api call:

```py
from lib.db import pool, query_wrap_array

    sql = query_wrap_array("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    """)
    print("SQL--------------")
    print(sql)
    print("SQL--------------")
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        # this will return a tuple
        # the first field being the data
        json = cur.fetchone()
    print("-------------------")
    print(json[0])
    return json[0]
```

## Setting up PROD DB 

```sh
export PROD_CONNECTION_URL="postgresql://root:<Password>@<DB Endpoint Name>:5432/cruddur"

gp env PROD_CONNECTION_URL="postgresql://root:<Password>@<DB Endpoint Name>:5432/cruddur"

psql $PROD_CONNECTION_URL
```

## Connect to RDS via Gitpod

In order to connect to the RDS instance we need to provide our Gitpod IP and whitelist for inbound traffic on port 5432.

```sh
GITPOD_IP=$(curl ifconfig.me)
```


We'll create an inbound rule for Postgres (5432) and provide the GITPOD ID.

We'll get the security group rule id so we can easily modify it in the future from the terminal here in Gitpod.

```sh
export DB_SG_ID="<General SecurityGroupRuleId>"
gp env DB_SG_ID="<General SecurityGroupRuleId>"

export DB_SG_RULE_ID="<SecurityGroupRuleId>"
gp env DB_SG_RULE_ID="<SecurityGroupRuleId>"
```

Whenever we need to update our security groups we can do this for access.
```sh
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```

![Security Groups](assets/Week04-SG.png)<br>

Then we will create a binary file `backend-flask/bin/rds-update-sg-rule`:

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="rds-update-sg-rule"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
> change the file permission `chmod u+x bin/rds-update-sg-rule`


## Update Gitpod IP on new env var

We'll add a command step for postgres:

```sh
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"
```

We will update `backend-flask/bin/db-connect` to connect PROD DB as well:

```sh
#! /usr/bin/bash
if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL
```

Then we edit the `docker-compose.yml` file to redirect the connection to PROD DB:

```yml
CONNECTION_URL: "${PROD_CONNECTION_URL}"
```

![PROD-DB](assets/Week04-PROD-DB.png)<br>


