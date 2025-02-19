# Keycloak Benchmark

[![Java CI with Maven](https://github.com/keycloak/keycloak-benchmark/actions/workflows/build.yml/badge.svg)](https://github.com/keycloak/keycloak-benchmark/actions/workflows/build.yml)

This repository contains the necessary tools to run performances tests on a Keycloak server.

Section `Dataset` is to prefill the Keycloak/RHSSO DB with big amount of objects. Then section `Gatling` is to run the performance test itself
and generate some load. 

## Dataset

Dataset module is useful to populate target Keycloak/RHSSO server with many objects. For example:
- Populate your Keycloak realm with many users. This is useful when you want to run performance test with many concurrent user logins
and use different users for each login
- Populate your realm with many clients. This is useful for test service account logins and others...
- Populate your Keycloak server with many realms. Each realm will be filled with specified amount of roles, clients, groups and users, so this endpoint
might be sufficient for most of performance testing use-cases.

### Setup

The approach is to deploy the REST resource provider to the target Keycloak/RHSSO server. Then invoke REST requests to create many objects
of specified type.

**WARNING:** Approach of use Keycloak Admin REST API directly is slow in many environments and hence this approach is used to fill the data quickly. Make sure that 
in the production environment, this REST provider is not deployed (it is only for the purpose to quickly fill DB with the data, but should never be used in production). 


First is needed to build the provider, then to deploy it to the target Keycloak.

Build the project and deploy to the target Keycloak/RHSSO server

    mvn clean install -am -pl dataset
    cp dataset/target/keycloak-benchmark-dataset-*.jar $KEYCLOAK_HOME/standalone/deployments/
    
Instead of copying to `standalone/deployments`, the alternative is to deploy as a module

    mvn clean install
    export JAR_NAME=$(ls dataset/target/keycloak-benchmark-dataset-*.jar)
    $KEYCLOAK_HOME/bin/jboss-cli.sh --command="module add --name=org.keycloak.keycloak-benchmark --resources=$JAR_NAME --dependencies=org.keycloak.keycloak-common,org.keycloak.keycloak-core,org.keycloak.keycloak-server-spi,org.keycloak.keycloak-server-spi-private,org.keycloak.keycloak-services,org.keycloak.keycloak-model-infinispan,javax.ws.rs.api,org.jboss.resteasy.resteasy-jaxrs,org.jboss.logging,org.infinispan,org.infinispan.commons,org.infinispan.client.hotrod,org.infinispan.persistence.remote"

Then in the file `$KEYCLOAK_HOME/standalone/configuration/standalone.xml` add this additional line to the `providers` element of keycloak server subsystem:

    <provider>module:org.keycloak.keycloak-benchmark</provider>
    
See Keycloak server development guide for more details.

### Create many realms

You need to call this HTTP REST requests. This request is useful for create 10 realms. Each realm will contain specified amount of roles, clients, groups and users:

    http://localhost:8080/auth/realms/master/dataset/create-realms?count=10
    
### Create many clients
    
This is request to create 100 new clients in the realm `realm-5` . Each client will have service account enabled and secret
like <<client_id>>-secret (For example `client-156-secret` in case of the client `client-156`):

    http://localhost:8080/auth/realms/master/dataset/create-clients?count=200&realm-name=realm-5

You can also configure the access-type (`bearer-only`, `confidential` or `public`) and whether the client should be a
service-account-client with these two parameters:

    ...&client-access-type=bearer-only&service-account-client=false
 
### Create many users
   
This is request to create 500 new users in the `realm-5`. Each user will have specified amount of roles, client roles and groups,
which were already created by `create-realms` endpoint. Each user will have password like <<Username>>-password . For example `user-156` will have password like
`user-156-password` :

    http://localhost:8080/auth/realms/master/dataset/create-users?count=1000&realm-name=realm-5
    
### Create many events
   
This is request to create 10M new events in the available realms with prefix `realm-`. For example if we have 100 realms
like `realm-0`, `realm-1`, ... `realm-99`, it will create 10M events randomly in them

    http://localhost:8080/auth/realms/master/dataset/create-events?count=10000000
    
### Create many offline sessions
   
This is request to create 10M new offline sessions in the available realms with prefix `realm-`. For example if we have 100 realms
like `realm-0`, `realm-1`, ... `realm-99`, it will create 10M events randomly in them

    http://localhost:8080/auth/realms/master/dataset/create-offline-sessions?count=10000000    
    
### Remove many realms

To remove all realms with the default realm prefix `realm`

    http://localhost:8080/auth/realms/master/dataset/remove-realms?remove-all=true
    
You can use `realm-prefix` to change the default realm prefix. You can use parameters to remove all realms for example just from `foorealm5` to `foorealm15`

    localhost:8080/auth/realms/master/dataset/remove-realms?realm-prefix=foorealm&first-to-remove=5&last-to-remove=15          
    
### Change default parameters
    
For change the parameters, take a look at [DataSetConfig class](dataset/src/main/java/org/keycloak/benchmark/dataset/config/DatasetConfig.java)
to see available parameters and default values and which endpoint the particular parameter is applicable. For example to create realms with prefix `foo`
and with just 1000 hash iterations used for the password policy, you can use these parameters:

    http://localhost:8080/auth/realms/master/dataset/create-realms?count=10&realm-prefix=foo&password-hash-iterations=1000
    
The configuration is written to the server log when HTTP endpoint is triggered, so you can monitor the progress and what parameters were effectively applied.

Note that creation of new objects will automatically start from the next available index. For example when you trigger endpoint above
for creation many clients and you already had 230 clients in your DB (`client-0`, `client-1`, .. `client-229`), then your HTTP request
will start creating clients from `client-230` .

### Check last items of particular object

To see last created realm index

    http://localhost:8080/auth/realms/master/dataset/last-realm
    
To see last created client in given realm

    http://localhost:8080/auth/realms/master/dataset/last-client?realm-name=realm5
    
To see last created user in given realm

    http://localhost:8080/auth/realms/master/dataset/last-user?realm-name=realm5  


### Ability to clear caches and remote caches

With the RHDG integration enabled, it may be useful to clear the content of the remote caches or see if particular item is available in the remote cache.
Those endpoints are not directly to dataset or performance tests, however they are generally useful for those cases. They are useful just with the
RHDG integration enabled.

Clear all the items in the specified cache - in this case cache `sessions`:
 
    http://localhost:8080/auth/realms/master/cache/sessions/clear

Clear all session related caches:

    http://localhost:8080/auth/realms/master/cache/clear-sessions

Clear all the items in the specified remote cache - in this case cache `sessions`:
 
    http://localhost:8080/auth/realms/master/remote-cache/sessions/clear
 
See the count of items in all the available caches and remote caches:

    http://localhost:8080/auth/realms/master/cache/sizes
    
See if item with ID "123" exists in the specified cache:

    http://localhost:8080/auth/realms/master/cache/sessions/contains/123
    
See if item with ID "123" exists in the specified remote cache:

    http://localhost:8080/auth/realms/master/remote-cache/sessions/contains/123
    
## Benchmark
 
[How to Run the Keycloak Benchmark module](benchmark/BENCHMARK.md)

## Release

If you need to do changes in the "dataset" and then consume it for example from the Openshift pods, you may need the ability to push
your changes to the Keycloak and the release it. The info on how to release is in the [RELEASE.md](RELEASE.md).