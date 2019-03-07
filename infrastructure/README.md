# Infrastructure

This projects sets up a VPC and subnet to place assets in, and erects a Docker Swarm using an [overlay network](https://docs.docker.com/network/network-tutorial-overlay/) across a number of EC2 instances.

The swarm master instance is an EC2 instance in the "public" network, on a host with a public IP address so that it can be easily accessed from "outside". The swarm worker instances are all in the "private" network, and are not directly accessible from "outside" the environment.

## Prequisites
It is assumed that:
 - appropriate AWS credentials are available
 - terraform is available (this was developed with 0.11.11 and provider.aws v1.60.0)
 - the scripts are being run on a unix account.

## Usage

 - use values from `bootstrap\backend` to update `backend.tf` if necessary
 - create  `terraform.tfvars` from `terraform.tfvars.template`
 - apply `terraform init` then `terraform apply`

On successful completion, information is reported that you may need to set up other assets:

```
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

private_subnet = 172.28.10.64/26
public_subnet = 172.28.10.0/26
service_url = http://3.8.172.140
swarm_master = 3.8.172.140
visualizer_url = http://3.8.172.140:8080
vpc_id = vpc-040c83ea6816a7df1
```

Once the instances are up, after a few minutes the Docker Swarm should also be active. Because the instances are using Amazon Linux 2, and they have the appropriate permissions, you can use [Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) to access a command line on them, without needing to SSH into them. Open a session on the manager, and see that the swarm has been created (this may take 3-5 minutes, so be patient):

```
sh-4.2$ sudo docker node ls
ID                            HOSTNAME                                      STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
pktjlve8m0hc8yr4gnywhp6xf *   ip-172-28-10-60.eu-west-2.compute.internal    Ready               Active              Leader              18.06.1-ce
nk67eb9f4t1n0z6u4tigzqv9w     ip-172-28-10-84.eu-west-2.compute.internal    Ready               Active                                  18.06.1-ce
8d6sjd4a0x51inh1wn8gsuby7     ip-172-28-10-103.eu-west-2.compute.internal   Ready               Active                                  18.06.1-ce
g8jyjvwgtma6jgcxne95tsh5o     ip-172-28-10-118.eu-west-2.compute.internal   Ready               Active                                  18.06.1-ce
z1u1id33vq6vc30whkwznya27     ip-172-28-10-120.eu-west-2.compute.internal   Ready               Active                                  18.06.1-ce
```

Once the swarm is active, you can create a service stack on it by creating the file `/tmp/docker-compose.yml` with this content:

```
version: "3"
services:
  web:
    image: thebellman/getting-started:latest
    deploy:
      placement:
        constraints: [node.role != manager]
      replicas: 6
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
      restart_policy:
        condition: on-failure
    ports:
      - "80:80"
    networks:
      - webnet
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
  redis:
    image: redis
    ports:
      - "6379:6379"
    volumes:
      - "/tmp/data:/data"
    deploy:
      placement:
        constraints: [node.role == manager]
    command: redis-server --appendonly yes
    networks:
      - webnet
networks:
  webnet:
```

and then executing

```
sh-4.2$ sudo docker stack deploy -c /tmp/docker-compose.yml getstart
Creating network getstart_webnet
Creating service getstart_web
Creating service getstart_visualizer
Creating service getstart_redis
```

All being well, you should now be able to visit <http://3.8.172.140:8080> to see the Docker visualiser application, and <http://3.8.172.140> to access the deployed application. Each time you refresh the application, you should see the visit count go up, and the reported Hostname change.

### Note
Handling of the Swarm token is not very clean in this example. We are sharing it between the Master and the Worker nodes using [Secrets Manager](https://aws.amazon.com/secrets-manager/). The secret may or may not exist when the bootstrap script is executed on the Master node, so the "create" operation may fail. To allow for this, we do a "create" followed by an "update" to ensure the secret is written.

In the Worker node, we do a fixed "sleep" before trying to read the token, hoping that this is enough time to allow the master to have written the secret.

A better solution for both of these, which is out of scope for the demonstration, is to use [ZooKeeper](https://zookeeper.apache.org/) or [Consul](https://www.consul.io/) to share and distribute state, and provide a simple way to spin while waiting on the token to be available.

It's important to note also that the [Redis](https://redis.io/) in play is minimally configured, and persisting it's state in `/tmp/data` is definitely not a recommended configuration for anything other than tests like this.


## Teardown

To teardown the infrastructure, execute `terraform destroy`. This may take several minutes to execute as tearing down the VPC can be slow. If the tear down fails, you may need to re-execute the destroy command - Terraform can be poor at destroying VPC dependencies in the expected order. If re-executing fails, I'm afraid you may have to remove the VPC dependencies by hand and do a final `terraform destroy` to clean up.

Note that the [Secrets Manager](https://aws.amazon.com/secrets-manager/) secret containing the swarm token may not be destroyed.
