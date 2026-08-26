# citrix-workspace-docker
Dockerized Citrix Workspace app for Linux
=======
# Citrix Workspace App (Docker) + Zoom VDI Plugin

This packages Citrix Workspace App for Linux, with the Zoom VDI Citrix
plugin, into a Docker container. 
By default, the latest Citrix Workspace version is fetched, however, Zoom VDI plugin version is hard-coded - that's for aligning to my companies version restrictions.

This project is heavily based on https://github.com/majorcs/ca.dcloud.ICAClient. 

## How to use

1. Make sure you have Docker service installed and enabled.
2. Make sure you have xauth isntalled.
3. Clone the repo to a folder. This will be considered as you're working directory, command should be ran from there.
4. Sudo run citrix_docker_starter.sh. On first run, it will ask to build the image. If it already exists, it'll start the container.
+1. You can put .ica files into ica-files subdir. This case that file will be picked up and used to launch.

## What was tested and works fine

- Teams/Zoom VDI offloading
- 2 HD monitors
- Audio devices passthrough

I'm using this from latest CachyOS distro.

## What was NOT tested yet

- Webcam

## Known issues

- Citrix forgots mail address, it must be given at every logins
- When starting a session, a blank screen appears, has to put to taskbar first and resize it back again. Seen on KDE 6.7.4
- Citrix AppProtection is not running, not yet debugged.