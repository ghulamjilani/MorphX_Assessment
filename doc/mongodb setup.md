### Setup a fresh MongoDB server [3.6]

This is a setup guide for single server, single shard production MongoDB. It meets our current requirements and leaves room for quick scaling.

Default AWS mongodb image already comes with ready to use mongodb server.

The default init script that comes with the installation attempts to detect the NUMA-ness of the machine, but fails to do so properly because `numactl` isn't installed. To fix this:

```
sudo apt-get install numactl
```

### `/etc/hosts` setup

You should set ip/host definition there for mongodb VDS. Example:

`10.0.0.153 immerss-mongodb.private`

#### Configuration

The default MongoDB installation configures the cluster to only contain 1 mongod process. Since our cluster is different, we need to modify the configuration:

#### Move default config file
```
sudo mv /opt/bitnami/mongodb/mongod.conf /opt/bitnami/mongodb/mongod_qa.conf
```

### Also don't forget to setup qa's config.

Edit `/opt/bitnami/mongodb/scripts/ctl.sh`. Change there `MONGODB_CONFIG_FILE` option to `/opt/bitnami/mongodb/mongod_qa.conf`
Edit `/opt/bitnami/mongodb/mongod_qa.conf`. Change `bind_ip` option to `immerss-mongodb.private` 

### Qa mongodb restart

`sudo /opt/bitnami/ctlscript.sh restart`

#### Create MongoDB directories necessary for our MongoDB setup

```
# Create directory for logs
sudo mkdir /opt/bitnami/mongodb/prod_log
sudo chown mongodb:mongodb /opt/bitnami/mongodb/prod_log

# Create directories for data
sudo mkdir /opt/bitnami/mongodb/data/prod_db
sudo mkdir /opt/bitnami/mongodb/data/prod_db/shard-1
sudo mkdir /opt/bitnami/mongodb/data/prod_db/config-1
sudo mkdir /opt/bitnami/mongodb/data/prod_db/config-2
sudo mkdir /opt/bitnami/mongodb/data/prod_db/config-3
sudo chown -R mongodb:mongodb /opt/bitnami/mongodb/data/prod_db

# Create directory for configuration files
sudo mkdir /opt/bitnami/mongodb/prod_conf
sudo chown mongodb:mongodb /opt/bitnami/mongodb/prod_conf

```

#### Configure systemd

`PATH_TO_PROD_CONFS/config` should be `Rails.root.join('config')`. But you may want not to deploy rails app on mongo server. So just copy them wherever you want and replace `PATH_TO_PROD_CONFS` with your folder where configs are.
```
sudo cp /PATH_TO_PROD_CONFS/production/mongodb/systemd/* /lib/systemd/system/

sudo cp /PATH_TO_PROD_CONFS/production/mongodb/startup-scripts/* /opt/bitnami/mongodb/bin/

sudo chmod +x /opt/bitnami/mongodb/bin/*.sh
sudo systemctl enable mongodb
```

#### Use our own configuration files

The following assumes that the code at the given location is up-to-date.

```
sudo cp PATH_TO_PROD_CONFS/production/mongodb/config/* /opt/bitnami/mongodb/prod_conf
```

#### Edit the configuration files

The `/opt/bitnami/mongodb/prod_conf/router.conf` file needs to be modified. The `sharding.configDB` key needs to be updated to use the correct host for MongoDB.

#### Start prod mongodb (also use systemctl if you want to stop/restart prod mongodb)

```
sudo systemctl start mongodb
```

#### Perform run-time configuration

Some parts of MongoDB can only be configured by issuing commands through the mongo console. Every time you delete the data directory as you did in the steps above, you will delete all run-time configuration data stored by MongoDB. To re-configure MongoDB properly, issue the following commands:

#### Initialize Config Servers

Connect to one of the **config** servers:

`mongo --port 27018 --host immerss-mongodb.private`

Initiate by entering the following:

```
rs.initiate(
  {
    _id: "configReplSet",
    configsvr: true,
    members: [
      { _id : 0, host : "immerss-mongodb.private:27018" },
      { _id : 1, host : "immerss-mongodb.private:27019" },
      { _id : 2, host : "immerss-mongodb.private:27020" }
    ]
  }
)
```

##### Add shards to the cluster

Make sure to leave the config server and now connect to the `mongo` router (27117, see `router.conf` for the exact router's port).

```
mongos> sh.addShard("immerss-mongodb.private:27021")
{ "shardAdded" : "shard0000", "ok" : 1 }
```

##### Enable sharding on `immerss_production`

```
mongos> use immerss_production
switched to db immerss_production
mongos> sh.enableSharding('immerss_production')
{ "ok" : 1 }
```

##### Logrotate

```
sudo cp PATH_TO_PROD_CONFS/production/logrotate-mongodb /etc/logrotate.d/mongodb
```

That is it, in order to scale Mongo to an additional servers, register another shard, pre-shard collections and if necessary configure the chunk size.
Previously the collections were pre-sharded as displayed below. If returning to multiple shard setup they should critically be reviewed and new collections should be included.

```
# from the mongos console
sh.shardCollection('immerss_production.chat_channels', { _id: 'hashed' })
sh.shardCollection('immerss_production.chat_messages', { _id: 'hashed' })
```
