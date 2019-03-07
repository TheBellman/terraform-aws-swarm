# terraform-aws-swarm
This project is used to demonstrate a Docker Swarm using an [overlay network](https://docs.docker.com/network/network-tutorial-overlay/) across a number of EC2 instances.

The swarm master instance is an EC2 instance in the "public" network, on a host with a public IP address so that it can be easily accessed from "outside". The swarm worker instances are all in the "private" network, and are not directly accessible from "outside" the environment.

Note that building a Docker Swarm on AWS in this way is not a particularly useful or clever thing to be doing - the managed [EKS](https://aws.amazon.com/eks/) and [ECS](https://aws.amazon.com/eks/) services are a much simpler and more easily secured way to deploy container stacks. Any time that we build EC2 instances and deploy services onto them, we are widening the attack surface, and increasing the number of things we need to ensure we have secured.

## Usage
First use the `bootstrap` sub-project to set up Terraform assets - refer to the [ReadMe](bootstrap/README.md) for further information. Next use the `infrastructure` sub-project to set up the VPC, network, EC2 instances and other assets - again, the [ReadMe](infrastructure/README.md) has further information.

## License
Copyright 2019 Little Dog Digital

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
