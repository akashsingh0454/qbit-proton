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

## Setup Instructions

### 1. Obtain ProtonVPN OpenVPN Configuration Files

1.  **Log in to your ProtonVPN Account:** Go to [https://account.protonvpn.com/login](https://account.protonvpn.com/login) and log in.
2.  **Navigate to Downloads:** Find the "Downloads" or "OpenVPN/IKEv2 configuration files" section in your account dashboard.
3.  **Select Platform and Protocol:**
    *   Choose **Linux** as your platform.
    *   Select the **UDP** protocol (generally recommended for speed).
4.  **Download Server Configuration:**
    *   Download the specific `.ovpn` server configuration file for the server you wish to use. Choose servers that support P2P traffic if that's your primary use case.
    *   Note the server hostname from the filename (e.g., `ch-us-ny-01.protonvpn.com.udp.ovpn`).
5.  **Place the `.ovpn` file:** In the same directory where you will clone or place this project's `Dockerfile` and `docker-compose.yml`, create a directory named `protonvpn-config`. Copy your chosen `.ovpn` file into this `./protonvpn-config/` directory.
    ```bash
    mkdir protonvpn-config
    # Example: cp ~/Downloads/ch-us-ny-01.protonvpn.com.udp.ovpn ./protonvpn-config/
    ```
    The `start.sh` script will use the first `.ovpn` file it finds in this directory. It's best to place only one.

### 2. Create Configuration and Download Directories

Create directories for qBittorrent's configuration and your downloads. These will be mounted as volumes by Docker.

```bash
mkdir qbittorrent-config
mkdir downloads
```

### 3. Configure Environment Variables (ProtonVPN Credentials)

Create a file named `.env` in the root of the project directory (same location as `docker-compose.yml`). Add your ProtonVPN credentials and the server hostname you selected:

```env
# .env
PROTONVPN_USER=your_protonvpn_openvpn_username
PROTONVPN_PASS=your_protonvpn_openvpn_password
PROTONVPN_SERVER=ch-us-ny-01.protonvpn.com # Replace with the actual server hostname from your .ovpn file
```

**Important:**
*   The `PROTONVPN_USER` and `PROTONVPN_PASS` are your OpenVPN/IKEv2 credentials, which can be different from your main ProtonVPN login. Find them in your ProtonVPN account dashboard, usually under "Account" -> "OpenVPN / IKEv2 username".
*   The `PROTONVPN_SERVER` is used by the startup script primarily for logging and reference. The actual server connected to is determined by the `.ovpn` file you placed in `protonvpn-config`. Ensure this matches or the script might show misleading info.

### 4. Build and Run the Container

Once the above setup is complete, you can build and start the container using Docker Compose:

```bash
sudo docker-compose up --build -d
```

*   `--build`: Forces Docker to rebuild the image if you've made changes to the `Dockerfile`.
*   `-d`: Runs the container in detached mode (in the background).

### 5. Access qBittorrent Web UI

After the container starts and the VPN connection is established (this might take a minute), you can access the qBittorrent Web UI by navigating to:

`http://<your_docker_host_ip>:9090`

Replace `<your_docker_host_ip>` with the IP address of the machine running Docker. If you're running it on the same machine you're browsing from, you can use `http://localhost:9090`.

The default qBittorrent credentials are:
*   Username: `admin`
*   Password: `adminadmin`

It is highly recommended to change these default credentials immediately after your first login.

## Important Notes

### P2P Port Forwarding

For optimal P2P performance (especially for seeding), you need to ensure the port qBittorrent uses for incoming connections is forwarded by ProtonVPN.
1.  **ProtonVPN Port Forwarding:** Some ProtonVPN servers and plans support port forwarding. Check your ProtonVPN account dashboard or their documentation to see if your chosen server supports it and how to enable it. You will get a specific port number from ProtonVPN.
2.  **qBittorrent Configuration:**
    *   In the qBittorrent Web UI, go to `Tools -> Options -> Connection`.
    *   Set the "Port used for incoming connections" to the port number provided by ProtonVPN.
3.  **Docker Compose Port Mapping:** If you have a dedicated forwarded port from ProtonVPN, you should also map it in the `docker-compose.yml` file. For example, if ProtonVPN forwards port `54321` to you:
    ```yaml
    # In docker-compose.yml services.qbittorrent-protonvpn.ports:
    # - "9090:9090" # WebUI
    - "54321:54321" # P2P Port TCP
    - "54321:54321/udp" # P2P Port UDP
    ```
    Then, restart the container: `sudo docker-compose up -d --force-recreate`.

### File Permissions (PUID/PGID)

The container runs qBittorrent as a non-root user `qbittorrent` created during the image build. Files created by qBittorrent inside the `/config` and `/downloads` volumes will be owned by this user.
If you experience permission issues with the mounted volumes on your host system, you may need to adjust ownership or permissions on the host directories (`./qbittorrent-config`, `./downloads`).

For more advanced control, you can modify the `Dockerfile` and `start.sh` to accept `PUID` (User ID) and `PGID` (Group ID) environment variables to run the qbittorrent process with your host user's IDs. This is a common practice but is not implemented by default in this setup.

### Checking Logs

To check the logs of the container (useful for troubleshooting VPN connection issues or qBittorrent errors):

```bash
sudo docker-compose logs -f qbittorrent-protonvpn
```

Or, if you didn't use the default container name:

```bash
sudo docker logs -f <container_id_or_name>
```

You can find the OpenVPN connection log inside the container at `/var/log/openvpn.log`.

## Stopping the Container

To stop the container:

```bash
sudo docker-compose down
```

This will stop and remove the container but will not delete the volumes (`./qbittorrent-config`, `./downloads`, `./protonvpn-config`), so your settings and data will persist.

## Disclaimer

Using P2P software carries risks. Ensure you are complying with the terms of service of ProtonVPN and any applicable laws in your region. This setup is provided for educational purposes.
