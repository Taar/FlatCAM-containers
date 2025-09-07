# FlatCAM Container Images

Collection of OCI compliant container images that contain all the required files to run FlatCAM.

## Source Code

These images use the source found at: https://github.com/dwrobel/flatcam/tree/mstanciu_Beta_8.995

## Why?

I wanted to make it very easy to run FlatCAM on *most* systems and also make it easy to maintain that application. So I settled on creating a collection of OCI compliant container images that contain pinned Python libraries and system dependencies needed to run FlatCAM.

While it is possible to run FlatCAM directly on the system using a Python virtual environment, the application's Python libraries depend on shared C libraries that can differ depending on the operating system flavour.

## Running the Containers

> [!NOTE]
> As of right now, Linux is the only supported platform until I have the time to test other operating systems.

Since FlatCAM is a GUI application, a graphical environment is needed in order to run the application. This means that the graphical environment running on the host needs to be accessible from the running container. Luckily, podman makes pretty easy to do this but there are some caveats.

Since a graphical environment is not packaged within these images, there might be some cases that the application will not run. If this happens, please open an issue with as much details as possible and I'll try my best to help.

As of right now, there is only one graphical environment supported, X11. This is because X11 is still the most widely used graphical environment for Linux and there are ways to run X11 applications on other operating systems.

> [!NOTE]
> *Most* wayland compositors support xwayland which is used to support legacy X11 applications. [xwayland-satellite](https://github.com/Supreeeme/xwayland-satellite) can be used if xwayland isn't started automatically by the wayland compositor.

Run the following command and FlatCAM should start after a few seconds.

```bash
podman run --rm -t -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v --userns=keep-id --security-opt=label=type:container_runtime_t ghrc.io/Taar/flatcam:xserver
```

### Desktop Entry

On Linux, create a file called, `FlatCAM.desktop` with the following within the `~/.local/share/applications/` directory.

```
[Desktop Entry]
Type=Application
Version=xserver-573707
Name=FlatCAM
Exec=FlatCAM
```

Create a bash script named `FlatCAM` within the `~/.local/bin` directory with the following:

```bash
#!/usr/bin/env bash

mkdir -p "$HOME/Documents/FlatCAM/"

exec podman run --rm -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v "$HOME/Documents/FlatCAM:/home/gnuplususer/Documents/FlatCAM" --userns=keep-id --security-opt=label=type:container_runtime_t ghrc.io/Taar/flatcam:xserver-573707
```

> [!NOTE]
> Don't forget to make the file executable!
> `chmod u+x FlatCAM`

## Building the Images

```bash
podman build . --target xserver -t flatcam:xserver
```

### Available Tags

- `latest`, `xserver`, `xserver-573707`

## Roadmap

- [ ] Image flavour with support for wayland compositors without using xwayland
  - Qt 6 has wayland support afaik
- [ ] Image flavour for external access using VNC
  - Configure a basic wlroots based compositor and setup [wayvnc](https://github.com/any1/wayvnc)
  - This should allow FlatCAM to be ran on systems that cannot run X11 applications
