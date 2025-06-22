# qBittorrent with ProtonVPN via Docker (ARM64 Optimized)

This project provides a Docker setup to run qBittorrent tunneled through ProtonVPN. It is optimized for ARM64 architectures (e.g., Raspberry Pi 4 and other ARM-based devices).

## Features

*   qBittorrent (headless version: `qbittorrent-nox`)
*   OpenVPN connection to ProtonVPN
*   ARM64 compatible
*   Easy deployment with Docker Compose
*   Persistent qBittorrent configuration and downloads

## Prerequisites

1.  **Docker and Docker Compose:** Ensure you have Docker and Docker Compose installed on your ARM64 system.
    *   Install Docker: [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)
    *   Install Docker Compose: [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)
2.  **ProtonVPN Account:** You need an active ProtonVPN account (Free or Paid). Paid plans often offer access to more servers, including P2P-optimized ones.
3.  **ProtonVPN OpenVPN Configuration Files:** You will need to download these from your ProtonVPN account.
4.  **Portainer (Optional):** If you prefer to use Portainer, ensure it's installed and managing your Docker environment.

## Setup Instructions

**Note:** The following steps assume you are deploying via the command line with `docker-compose`. For Portainer deployment, see the "Deploying with Portainer" section below after completing steps 1-3 for file preparation.

### 1. Obtain ProtonVPN OpenVPN Configuration Files

1.  **Log in to your ProtonVPN Account:** Go to [https://account.protonvpn.com/login](https://account.protonvpn.com/login) and log in.
2.  **Navigate to Downloads:** Find the "Downloads" or "OpenVPN/IKEv2 configuration files" section in your account dashboard.
3.  **Select Platform and Protocol:**
    *   Choose **Linux** as your platform.
    *   Select the **UDP** protocol (generally recommended for speed).
4.  **Download Server Configuration:**
    *   Download the specific `.ovpn` server configuration file for the server you wish to use. Choose servers that support P2P traffic if that's your primary use case.
    *   Note the server hostname from the filename (e.g., `ch-us-ny-01.protonvpn.com.udp.ovpn`).
5.  **Place the `.ovpn` file:** In a directory on your Docker host (e.g., `/opt/stacks/qbittorrent-protonvpn/`), create a subdirectory named `protonvpn-config`. Copy your chosen `.ovpn` file into this `protonvpn-config/` directory.
    ```bash
    # Example:
    # sudo mkdir -p /opt/stacks/qbittorrent-protonvpn/protonvpn-config
    # sudo cp ~/Downloads/ch-us-ny-01.protonvpn.com.udp.ovpn /opt/stacks/qbittorrent-protonvpn/protonvpn-config/
    ```
    The `start.sh` script will use the first `.ovpn` file it finds in this directory. It's best to place only one.
    **Note for Portainer Users:** You will need to ensure the paths used in the Portainer stack configuration for volumes correctly point to where you've placed these files on your Docker host.

### 2. Create Configuration and Download Directories

On your Docker host, create directories for qBittorrent's configuration and your downloads.
```bash
# Example:
# sudo mkdir -p /opt/stacks/qbittorrent-protonvpn/qbittorrent-config
# sudo mkdir -p /opt/stacks/qbittorrent-protonvpn/downloads
```
Adjust permissions if necessary so that the container user can write to them. See "File Permissions (PUID/PGID)" under "Important Notes".

### 3. Configure Environment Variables (ProtonVPN Credentials)

If using `docker-compose` CLI, create a file named `.env` in the same directory as your `docker-compose.yml`. Add your ProtonVPN credentials:
```env
# .env
PROTONVPN_USER=your_protonvpn_openvpn_username
PROTONVPN_PASS=your_protonvpn_openvpn_password
PROTONVPN_SERVER=ch-us-ny-01.protonvpn.com # Replace with the actual server hostname
```
**Important:**
*   The `PROTONVPN_USER` and `PROTONVPN_PASS` are your OpenVPN/IKEv2 credentials. Find them in your ProtonVPN account dashboard.
*   The `PROTONVPN_SERVER` is used by the startup script. Ensure this matches your chosen server.
**Note for Portainer Users:** You will typically set these environment variables directly in the Portainer UI when deploying the stack, instead of using a `.env` file.

### 4. Build and Run the Container (via Docker Compose CLI)

This is the command-line method. If using Portainer, skip to the next section.
Place the `Dockerfile`, `docker-compose.yml`, and `start.sh` from this project into your chosen directory (e.g., `/opt/stacks/qbittorrent-protonvpn/`).
Then, from that directory:
```bash
sudo docker-compose up --build -d
```
*   `--build`: Rebuilds the image if `Dockerfile` or `start.sh` changed.
*   `-d`: Runs in detached mode.

### 5. Access qBittorrent Web UI

After the container starts and the VPN connection is established (this might take a minute), access the qBittorrent Web UI:
`http://<your_docker_host_ip>:9090`
Default credentials: Username: `admin`, Password: `adminadmin`. Change these immediately.

## Deploying with Portainer (Alternative to Docker Compose CLI)

If you prefer using Portainer to manage your Docker containers, you can deploy this setup as a "Stack". A Portainer Stack uses a `docker-compose.yml` file.

**Prerequisites for Portainer Deployment:**
*   Portainer installed and connected to your Docker environment.
*   You have completed **Step 1 (Obtain ProtonVPN Config)** and **Step 2 (Create Config/Download Dirs)** from the "Setup Instructions" above, ensuring the `protonvpn-config`, `qbittorrent-config`, and `downloads` directories are created on your Docker host system at known paths.

**Portainer Deployment Steps:**

1.  **Navigate to Stacks:** In Portainer, go to "Stacks" in the left-hand menu.
2.  **Add Stack:** Click the "+ Add stack" button.
3.  **Name the Stack:** Give your stack a name, e.g., `qbittorrent-protonvpn`.
4.  **Build Method:** Choose "Web editor".
5.  **Copy Docker Compose Content:** Copy the entire content of the `docker-compose.yml` file from this project and paste it into Portainer's web editor.
    ```yaml
    version: '3.8'

    services:
      qbittorrent-protonvpn:
        build: ./ # Portainer needs a Git repo or URL to build. See note below.
        # image: your_custom_built_image_name:latest # Alternative if you pre-build
        container_name: qbittorrent-protonvpn
        cap_add:
          - NET_ADMIN
        devices:
          - /dev/net/tun:/dev/net/tun
        ports:
          - "9090:9090" # qBittorrent Web UI
          # - "6881:6881"
          # - "6881:6881/udp"
        volumes:
          # IMPORTANT: Update these paths to the absolute paths on your Docker host
          # where you created the directories in Steps 1 & 2 of Setup Instructions.
          - /opt/stacks/qbittorrent-protonvpn/protonvpn-config:/etc/openvpn/protonvpn:ro
          - /opt/stacks/qbittorrent-protonvpn/qbittorrent-config:/config
          - /opt/stacks/qbittorrent-protonvpn/downloads:/downloads
          # Optional:
          # - /etc/localtime:/etc/localtime:ro
        environment:
          # These will be set in the 'Environment variables' section below
          # PROTONVPN_USER: ""
          # PROTONVPN_PASS: ""
          # PROTONVPN_SERVER: ""
          QBITTORRENT_WEBUI_PORT: 9090
          # PUID: 1000 # Optional
          # PGID: 1000 # Optional
          # TZ: America/New_York # Optional
        sysctls:
          - net.ipv6.conf.all.disable_ipv6=0
        restart: unless-stopped
    ```
    **Important Note on `build: ./` with Portainer:**
    *   Portainer's "Web editor" for stacks typically expects an already built image specified with `image: your_image_name`.
    *   If you want Portainer to build the image directly, you usually need to point it to a Git repository containing the `Dockerfile` and associated files.
    *   **Workaround/Recommended approach for Portainer:**
        1.  Clone this project (or copy `Dockerfile` and `start.sh`) to your Docker host.
        2.  Build the image manually once using `docker build -t qbittorrent-protonvpn-custom .` in that directory.
        3.  Then, in the Portainer stack's `docker-compose` content, replace `build: ./` with `image: qbittorrent-protonvpn-custom:latest`.
        4.  Ensure the `volumes` section in the compose data correctly maps to the `protonvpn-config`, `qbittorrent-config`, and `downloads` directories you created on the host. The example above uses `/opt/stacks/qbittorrent-protonvpn/`. **You must adjust these paths.**

6.  **Environment Variables:** Scroll down to the "Environment variables" section in Portainer.
    *   Click "Add environment variable" three times.
    *   Set the following (using the "Advanced mode" for simple key-value pairs if preferred, or just "Simple mode"):
        *   `PROTONVPN_USER` = `your_protonvpn_openvpn_username`
        *   `PROTONVPN_PASS` = `your_protonvpn_openvpn_password`
        *   `PROTONVPN_SERVER` = `your_chosen_protonvpn_server_hostname` (e.g., `ch-us-ny-01.protonvpn.com`)
    *   You can also add `PUID`, `PGID`, and `TZ` here if desired.

7.  **Deploy the Stack:** Click the "Deploy the stack" button. Portainer will pull the necessary images (or use your custom-built one) and create the container according to the compose file and environment variables.

8.  **Access and Manage:** Once deployed, you can manage the stack (view logs, stop, restart, delete) from the "Stacks" list in Portainer. Access the qBittorrent Web UI as described in "Access qBittorrent Web UI" above.

## Important Notes

### P2P Port Forwarding 
(Content remains the same)

### File Permissions (PUID/PGID)
(Content remains the same, but it's especially important to note for Portainer volume mapping that host paths need correct permissions)

### Checking Logs
(Content remains the same, Portainer also offers a log viewer per container)

## Stopping the Container
(Content for docker-compose CLI remains, Portainer users would use the Portainer UI to stop/remove stacks or containers)

## Disclaimer
(Content remains the same)
