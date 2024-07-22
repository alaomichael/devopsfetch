```markdown

# DevOpsFetch

DevOpsFetch is a tool for retrieving and monitoring server information, designed to be easy to deploy and use with Docker.

## Features

- Display all active ports and services.
- Provide detailed information about a specific port.
- List all Docker images and containers.
- Provide detailed information about a specific container.
- Display all Nginx domains and their ports.
- Provide detailed configuration information for a specific domain.
- List all users and their last login times.
- Provide detailed information about a specific user.
- Display activities within a specified time range.
- Continuous monitoring and logging of server activities.

## Installation

### Build the Docker Image

```sh
docker build -t devopsfetch .
```

### Run the Container

```sh
docker run --rm -it --name devopsfetch devopsfetch [OPTIONS]
```

Replace `[OPTIONS]` with the desired options as described below.

## Options

### `-p, --port [port_number]`

Display all active ports or detailed information about a specific port.

#### Example: Display all active ports

```sh
docker run --rm -it --name devopsfetch devopsfetch -p
```

#### Example: Display detailed information about a specific port (e.g., port 80)

```sh
docker run --rm -it --name devopsfetch devopsfetch -p 80
```

### `-d, --docker [container]`

List Docker images and containers or detailed information about a specific container.

#### Example: List all Docker images and containers

```sh
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock --name devopsfetch devopsfetch -d
```

#### Example: Display detailed information about a specific container (e.g., container `nginx`)

```sh
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock --name devopsfetch devopsfetch -d nginx
```

### `-n, --nginx [domain]`

Display all Nginx domains and ports or detailed information about a specific domain.

#### Example: Display all Nginx domains and their ports

```sh
docker run --rm -it --name devopsfetch devopsfetch -n
```

#### Example: Display detailed configuration information for a specific domain (e.g., `example.com`)

```sh
docker run --rm -it --name devopsfetch devopsfetch -n example.com
```

### `-u, --users [username]`

List all users and their last login times or detailed information about a specific user.

#### Example: List all users and their last login times

```sh
docker run --rm -it --name devopsfetch devopsfetch -u
```

#### Example: Display detailed information about a specific user (e.g., `john`)

```sh
docker run --rm -it --name devopsfetch devopsfetch -u john
```

### `-t, --time [start] [end]`

Display activities within a specified time range.

#### Example: Display activities from `2023-07-01` to `2023-07-21`

```sh
docker run --rm -it --name devopsfetch devopsfetch -t "2023-07-01" "2023-07-21"
```

### `-m, --monitor`

Start continuous monitoring and logging of server activities.

#### Example: Start continuous monitoring and logging

```sh
docker run --rm -it --name devopsfetch devopsfetch -m
```

### `-h, --help`

Show the help message with usage instructions.

#### Example: Display the help message

```sh
docker run --rm -it --name devopsfetch devopsfetch -h
```

## Logging

When using the `-m` or `--monitor` option, DevOpsFetch will log activities to `/var/log/devopsfetch.log`. Log rotation is configured to ensure logs are rotated daily and up to 7 rotated logs are kept. Logs are compressed to save space.

## Example Commands

### Build the Docker Image

```sh
docker build -t devopsfetch .
```

### List all active ports

```sh
docker run --rm -it --name devopsfetch devopsfetch -p
```

### Display detailed information about port 80

```sh
docker run --rm -it --name devopsfetch devopsfetch -p 80
```

### List all Docker images and containers

```sh
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock --name devopsfetch devopsfetch -d
```

### Display detailed information about the `nginx` container

```sh
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock --name devopsfetch devopsfetch -d nginx
```

### Display all Nginx domains and their ports

```sh
docker run --rm -it --name devopsfetch devopsfetch -n
```

### Display detailed configuration for the domain `example.com`

```sh
docker run --rm -it --name devopsfetch devopsfetch -n example.com
```

### List all users and their last login times

```sh
docker run --rm -it --name devopsfetch devopsfetch -u
```

### Display detailed information about the user `john`

```sh
docker run --rm -it --name devopsfetch devopsfetch -u john
```

### Display activities from `2023-07-01` to `2023-07-21`

```sh
docker run --rm -it --name devopsfetch devopsfetch -t "2023-07-01" "2023-07-21"
```

### Start continuous monitoring and logging

```sh
docker run --rm -it --name devopsfetch devopsfetch -m
```

### Display the help message

```sh
docker run --rm -it --name devopsfetch devopsfetch -h
```

```
