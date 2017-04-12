WHODIS
======

Whodis is a sample app built to demonstrate the use of AWS CloudFormation and
Elastic Beanstalk for deploying a Docker-based app. The app itself provides a
very simple "What's my IP?" REST API.

![](https://media.tenor.co/images/8029940a475103b4a752b40953af3c68/tenor.gif)


Setup
-----

To run and deploy this app, you must have recent versions of the following:
* **Docker** (Docker for Mac is fine)
* **AWS CLI** must be configured with IAM credentials and a default region

Note: you must be on Linux or a macOS.


Running locally
---------------

Use the following command to build Whodis into a Docker image and run it
locally:

```
bin/run-app.sh
```

Note that the first time you run it, the Docker base image and some
dependencies will be downloaded, which may take a while.

By default it will expose HTTP on port 8080 of localhost. To override the port,
export `WHODIS_PORT` before running.

Use Ctrl-C to exit.


Running on AWS
--------------

Whodis uses several AWS services, all deployed with CloudFormation. The basic
rundown is:
* **Elastic Beanstalk** provides the foundation of the app.
* **Elastic Container Service** is deployed and managed by beanstalk, and
  provides the Docker execution platform.
* **Elastic Load Balancer** is also automatically deployed and managed by
  beanstalk, and provides HTTP load balancing and health checks.
* An **Elastic Container Registry** is deployed separately by CloudFormation,
  and is used to host the Docker images. It is pushed to by the build, and
  pulled by the ECS instances.
* An **S3** bucket is used to store Beanstalk deployment manifests.
* **IAM** roles and policies are used to wire together the authorization between
  the services.


There are two steps to a deploy of Whodis. The first time you deploy, you must
set up all the infrastructure via CloudFormation. Use the following script:

```
bin/deploy-infrastructure.sh
```

This will take around 10 minutes or longer to create all of the above resources
and tie them together.

Afterwards, you can deploy the latest local copy of the code with:

```
bin/deploy-app.sh
```

This command:
1. Builds the Docker image, tags it, and pushes to the container registry
2. Builds the EB manifest and pushes it to the deployment bucket
3. Updates the EB environment to load in the new app version.

When completed, the URL will be printed. You can also get the URL anytime by
running:

```
bin/get-url.sh
```

There's one other nice trick: if you want to roll back to an earlier-deployed
version, you can do so by passing the version string to the `deploy-app.sh`
script.

To tear down the infrastructure, use the following command:

```
bin/destroy-infrastructure.sh
```

Note that the destroy is asynchronous and this command will return immediately.


Functionality
-------------

Whodis provides very little useful functionality. Its main purpose is to
help you figure out your external-facing IP address. It also includes some
fun but often unreliable GeoIP lookups.

Here are some example `curl` commands:


Get IP info as JSON:
```
WHODIS_URL=$(bin/get-url.sh)

curl $WHODIS_URL
{
  "city": "Chicago",
  "country": "United States",
  "hostname": "your.external-facing-hostname.com",
  "ip": "1.2.3.4"
}
```

Get just an IP:
```
curl -H "Accept: text/plan" $WHODIS_URL
1.2.3.4
```

Check for some open ports on your IP:
```
curl -H "content-type: application/json" -d "[22, 80]" $WHODIS_URL/ports
{
  "ip": "1.2.3.4",
  "ports": [
    {
      "port": 22,
      "reachable": true
    },
    {
      "port": 80,
      "reachable": false
    }
  ]
}
```
