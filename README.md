# DockerFiles
collection of dockerfiles for development

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

Most of this project assumes an OS X install, and Docker for Mac, but could be easily translated to other operating systems, and for Docker Machine users one of the few differences would be on the IP address of the VM (as in requires IP address instead of localhost).

In Docker for Mac, the Docker team has swapped out Virtualbox for the xhyve hypervisor (👏👏👏). xhyve runs Alpine linux, which runs the Docker host. So the Docker client running in OS X communicates with the Docker host on Alpine. This stack has a few key advantages over the Docker Original stack:

Access containers using localhost, rather than the VM IP address
xhyve runs entirely in user space and has access to the host file system so tools like nodemon and watchman behave they same way they do natively

What we cover:
- Accessing our apps using a .dev TLD.
- Avoiding port collisions.
- Serving static files.
- Refreshing browser on file changes.

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

# Avoiding port collisions.


