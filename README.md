# DockerFiles
A collection of dockerfiles and boilerplates for development

# Images
## WebLayer/Proxy
- nginx
- ssl
- proxy
- `andyshinn/dnsmasq` [DNS for development](# Accessing our apps using a .dev domain names)

## App Layer
- nodejs
- jboss
- python

## Data Layer
- mongo
- redis
- mysql
- postgres

# Development Environment setup

Most of this project assumes an OS X install, and Docker for Mac, but could be easily translated to other operating systems, and for Docker Machine users one of the few differences would be on the IP address of the VM (as in requires IP address instead of localhost).

In Docker for Mac, the Docker team has swapped out Virtualbox for the xhyve hypervisor (👏👏👏). xhyve runs Alpine linux, which runs the Docker host. So the Docker client running in OS X communicates with the Docker host on Alpine. This stack has a few key advantages over the Docker Original stack:

Access containers using localhost, rather than the VM IP address
xhyve runs entirely in user space and has access to the host file system so tools like nodemon and watchman behave they same way they do natively

What we cover:
- Docker
- Docker Compose
- Accessing our apps using a .dev TLD.
- Proxy service.
- Serving static files.

## DOCKER

If you haven't heard about Docker yet or you're not familiar with its concepts I would recommend the amazing Docker docs and read a few tutorials online.

> DOCKER PROVIDES A WAY TO RUN APPLICATIONS SECURELY ISOLATED IN A CONTAINER, PACKAGED WITH ALL ITS DEPENDENCIES AND LIBRARIES. [HTTPS://DOCS.DOCKER.COM]

So what is Docker? It helps you to prepare a reproducible encapsulated environment for your application where only those dependencies exist, that are necessary to start. For Node.js applications this would mean the `node` executable, your source code and your npm dependencies (and maybe some c/c++ tooling).

Why do we need it? Have you ever experienced "it works on my machine"? You tested it locally, all tests pass but on your colleagues machine it's failing (or worse, it's failing in production)? With Docker we can create an isolated environment which is reproducible on other machines (though of course, you cannot run the `node` x86 executable on an ARM machine).

In addition to creating an encapsulated environment, Docker can also create images of this environment. Imagine you download `node`, install your npm dependencies and then, together with your source code create a tarball (or zip archive). This image can then be shipped to any other machine and started there. This saves the overhead of e.g. running `npm install` on other machines, which is why it's way faster. Also, Docker uses a layered file system for its images, which means only the parts which change will be sent over the network when the image is updated.

## DOCKER-COMPOSE

OK we heard about some basic functions of Docker, but what do we need to do if our service needs a database? To solve this problem, we can use `docker-compose`. It can easily orchestrate many services using configuration files. All common things you can do with Docker through the command line can be configured in a `docker-compose.yml` configuration file.

# Accessing our apps using a .dev domain names
Let's start by getting our beloved .dev suffix. In case you're not sure what it means, it would allow you to access your app under the .dev TLD from your local machine. For example, if your app is called pinataparty, you can access it by browsing to http://pinataparty.dev.

While this might seem cosmetic, as I described before, it frees us from having to remember which port an app is running on, and if you have several of them at the same time, avoiding port collisions. Plus, a proper domain name helps with cookies and authentication (who hasn't had a cookie on http://localhost:3000 belonging to a different app?).

## Setting up DNS
As you might have guessed, one of the things we'd need to tackle it's DNS. Since our apps are going to change over time, we can't use any static mappings in /etc/hosts.

We need to able to resolve anything that ends in .dev to a specific address, the address of a reverse proxy/forwarder (more on that later) that's running on our local computer.

We're going to run a small DNS server for that purpose, using that particular feature from dnsmasq. And we're going to run it through Docker so we'll not mess with our host.

```
docker run -d \
  --name dnsmasq \
  --restart always \
  -p 53535:53/tcp \
  -p 53535:53/udp \
  --cap-add NET_ADMIN \
  andyshinn/dnsmasq \
  --command --address=/dev/127.0.0.1
```

The most important part of this is the --command switch. For the sake of this discussion, we'll keep it simple, this is essentially telling dnsmasq that anything that ends in .dev should resolve to an address of 127.0.0.1. (Docker Machine/Boot2Docker users will need to change this address to the IP of the VM. Docker for Mac users: well we're lucky ones as of recent betas to be able to use localhost, aren't we?).

It's also worth noticing the ports, we're mapping ports 53535 on the host to port 53 on the container, for both TCP and UDP protocols. We used a higher port and avoided the default, because of the chance of conflicts.

Now we have a dumb DNS server that resolves anything ending in .dev to 127.0.0.1, but we're not using it yet. In OS X, we're going to create a specific configuration that would tell the system to use a specific nameserver when a particular condition occurs, in this case, the dev TLD. The process should be quite similar with resolv.conf in Linux.

We're going to create a file under `/etc/resolver/` called `dev` (notice it unsurprisingly matches our TLD), containing the following:

```
nameserver 127.0.0.1
port 53535
```

Again, for Docker Machine users you would specify the VM's IP here instead.

With those changes in place, we need to test it, it never hurts. OS X is a bit weird when it comes to how resolver works, so don't be fooled if you try:

```
$ nslookup anything.dev
Server:         192.168.0.1
Address:        192.168.0.1#53

Name:   anything.dev
Address: 127.0.53.53
```

Instead, we'll ping it:

```
$ ping -c1 anything.dev
PING anything.dev (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.043 ms
```

# The proxy service

We managed to get our DNS setup working. Now we need to dive deeper into what our forwarder or proxy might look like.

We need a service, but not any standard service as you might think. We would need it to be dynamic, since our list of running apps have the potential to be changing all the time. In DevOps terms, we're in need of a dynamic load balancer. And since we're running (or at least should be) most of our apps in Docker itself, it would be nice if it had tight integration with it.

Fortunately, there's such a thing. Not only that, you've plenty of options when it comes to it within the Docker ecosystem. In this article, we'll leverage nginx-proxy which provides even more than what we need.

nginx-proxy uses Docker events to reconfigure and reload Nginx, thus giving us a fully dynamic reverse proxy that we'll use to provide a backend for our DNS magic we just setup.

There are different ways to run it, but let's just try the easiest:

```
$ docker run \
  -p 80:80 \
  -p 443:443 \
  --name nginx-proxy \
  --restart always \
  -v /var/run/docker.sock:/tmp/docker.sock:ro \
  -v ./certs:/etc/nginx/certs \
  jwilder/nginx-proxy
```

Let's recap on our command. As in our previous DNS example, we're ensuring our container persists within restarts, and now we're exposing ports 80 and 443 (optional, required for SSL) and mounting a few volumes. The first one is a path to the Docker sock which is required by nginx-proxy to listen for events, and the second (and optional) contains our SSL certificates, for SSL support.

Alternatively use the docker-compose to build and start nginx proxy service
`docker-compose up web`

As you would expect, after running this command and navigating to http://localhost (again, Docker Machine users replace with VM's IP), we have a Nginx server running.

However, it shows a 503 page. This is standard, as we haven't told this proxy which app we want to access. Which brings us to...

## From symlinks to VIRTUAL_HOST

If you remember from above, one of the Pow niceties was the ability to setup symlinks to our apps. In the case of nginx-proxy which is even more powerful when it comes to routing, we specify our app name (or names, since it supports multiple) as an environment variable in our containers.

The magic happens with VIRTUAL_HOST. For any container we run with this environment variable, will be accessible under that name, which coupled with our DNS setup effectively achieves our goal of getting our multi-app, no port-colliding setup from Pow into our Docker setup. Due to introspection, we don't even need to expose the ports in our containers, and certainly not in the host.

We're going to start by testing it with a default Nginx website, which we're all familiar with.

```
$ docker run -it -e VIRTUAL_HOST=example.dev nginx
```

If we navigate to `http://example.dev` we should be able to see Nginx's default welcome page.

This is also the case for any containers we run as we described, any app with exposed ports, so you can leverage it within Docker Compose to further improve your development workflow.

I can't stress the productivity gains of this enough, you run an app server, you have a DNS name, you don't have to remember the port, you kill it it's gone. It's magical.

## Docker-compose orgnization

I'd like to explain how we organize our code. All of our services have their own service `docker-compose.yml` files.

Why does it matter? When we started setting up our dev environment, we of course searched to find solutions someone else described, but splitting up your code-base unfortunately makes it a little harder to connect all your services. At first glance this seems strange, as Docker was built for micro-services, but since docker-compose was the go-to tool for local orchestration, how should one docker-compose file know of your other services? Each repository has it's own separate docker-compose file to orchestrate databases, but you couldn't easily link a service that was described in a different file of which you didn't know the exact location. Some of the solutions proposed to create a top-level docker-compose file which then knows all the other services but this just looked awkward.

## THE SETUP WITH ONE SHARED DOCKER NETWORK

The final solution was to use one shared network. That sounds simple and it is.
You can view a list of all docker networks using this command:

`docker network ls`

### Option 1: Make your container requiring the link a member of the foreign networks

To do this, you need to add two sections to the docker compose file where you want to define the link: Make the specific container a member of the foreign network and define for the docker compose file itself that these networks are external.

```
version: '2'
services:
  test2:
    image: something
    external_links:
      - domainA_test1_1
    networks:
      - default
      - domainA_default
networks:
  domainA_default
    external: true

```
As you can see, “domainA_default” is the network that docker automatically has created for the composition “domainA”. Additionally, I’ve attached the service to the default network.

In test2, you can access test1 using it’s default DNS name “domainA_test1_1”.

### Option 2: Set bridge networking mode for all containers you want to link with each other

Option 1 allows for private networks linked with each other. However, you may run into issues if you need to initiate outbound connections from within your linked containers.

Therefore, another option is to enable the bridged networking mode for all the containers you want to link together:

```
version: '2'
services:
  test2:
    image: something
    network_mode: bridge
    external_links:
      - domainA_test1_1
```

```
version: '2'
services:
  test1:
    image: something
    network_mode: bridge

```

Which option is right for you, depends on your concrete situation. I personally prefer option 1, because it uses private networks instead of bridging the containers to the host network.