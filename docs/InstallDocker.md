# Installing Docker

## Step 1. Update Manjaro

This is an important step. I recommend you to make sure that your Manjaro system is up to date. Use the following command to update your system.

`sudo pacman -Syu`

This process could take few minutes, depends on the internet speed.

## Step 2. Install Docker

Use this command to install Docker

`sudo pacman -S docker`

Output:

```
resolving dependencies...
looking for conflicting packages...

Packages (2) bridge-utils-1.6-2 docker-1:18.05.0-2

Total Download Size: 32,87 MiB
Total Installed Size: 159,49 MiB

:: Proceed with installation? [Y/n]
```

Press Y and then Enter, to confirm the installation. After sometimes, Docker should be installed on your Manjaro system. Now run and enable Docker on startup.

```
sudo systemctl start docker
sudo systemctl enable docker
```

### Check Docker version

`sudo docker version`

It should return something like this

```
$ sudo docker version
Client:
 Version:           18.09.6-ce
 API version:       1.39
 Go version:        go1.12.4
 Git commit:        481bc77156
 Built:             Sat May 11 06:11:03 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server:
 Engine:
  Version:          18.09.6-ce
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.12.4
  Git commit:       481bc77156
  Built:            Sat May 11 06:10:35 2019
  OS/Arch:          linux/amd64
  Experimental:     false
```

Done. At this point, Docker is installed on Manjaro.

## Step 3. Configure Docker user

By default, only user with root or sudo privileges can run or manage Docker. If you want to run docker without root privileges or without having to add sudo everytime, do the following

`sudo usermod -aG docker $USER`

Then, reboot Manjaro.

Upon reboot, you can run docker commands without having to switch to root user or use sudo anymore. You can run with the current user privilege.

## Changing default install location of docker

Ensure docker stopped (or not started in the first place, e.g. if you've just installed it)

```
sudo systemctl stop docker
sudo systemctl daemon-reload
```

By default, the `daemon.json` file does not exist, because it is optional - it is added to override the defaults.
So new installs of docker and those setups that haven't ever modified it, won't have it, so create it:

`vi /etc/docker/daemon.json`

And add the following to tell docker to put all its files in this folder, e.g:

```
{
  "data-root": "/path/to/docker"
}
```

and save.

Now start docker:

`systemctl start docker`

(if root or prefix with sudo if other user.)

And you will find that docker has now put all its files in the new location, in my case, under: /path/to/docker.

## Install Compose on Linux systems

On Linux, you can download the Docker Compose binary from the Compose repository release page on GitHub.

- Run this command to download the current stable release of Docker Compose:

```sh
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

To install a different version of Compose, substitute 1.24.1 with the version of Compose you want to use.

- Apply executable permissions to the binary:

`sudo chmod +x /usr/local/bin/docker-compose`

Note: If the command docker-compose fails after installation, check your path. You can also create a symbolic link to /usr/bin or any other directory in your path.

For example:

```sh
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

Optionally, install command completion for the bash and zsh shell.

- Test the installation.

```sh
$ docker-compose --version
docker-compose version 1.24.1, build 1110ad01
```
