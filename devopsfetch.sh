#!/bin/bash

# Function to display all active ports and services
list_ports() {
  echo "Listing all active ports and services:"
  ss -tuln || echo "ss command not found or not working"
}

# Function to display detailed information about a specific port
port_details() {
  echo "Displaying details for port: $1"
  ss -tuln | grep ":$1" || echo "No information found for port $1"
}

# Function to list all Docker images and containers
list_docker() {
  echo "Listing all Docker images and containers:"
  docker ps -a || echo "Docker daemon not running"
  docker images || echo "Docker daemon not running"
}

# Function to display detailed information about a specific container
container_details() {
  echo "Displaying details for container: $1"
  docker inspect $1 || echo "No information found for container $1"
}

# Function to display all Nginx domains and their ports
list_nginx() {
  echo "Listing all Nginx domains and their ports:"
  nginx -T | grep -E 'server_name|listen' || echo "Nginx not installed or no configuration found"
}

# Function to display detailed configuration information for a specific domain
nginx_details() {
  echo "Displaying configuration for domain: $1"
  nginx -T | awk -v domain="$1" '
    $0 ~ "server_name " domain {
      show=1
    }
    $0 ~ "}" {
      show=0
    }
    show
  ' || echo "No configuration found for domain $1"
}

# Function to list all users and their last login times
list_users() {
  echo "Listing all users and their last login times:"
  lastlog || echo "lastlog command not found"
}

# Function to display detailed information about a specific user
user_details() {
  echo "Displaying details for user: $1"
  lastlog | grep "^$1" || echo "No information found for user $1"
}

# Function to display activities within a specified time range
time_range() {
  echo "Displaying activities from $1 to $2"
  journalctl --since="$1" --until="$2" || echo "journalctl command not found or no logs available"
}

# Function to start continuous monitoring and logging
monitor() {
  echo "Starting continuous monitoring and logging"
  while true; do
    echo "Logging system activities at $(date)" >> /var/log/devopsfetch.log
    ss -tuln >> /var/log/devopsfetch.log
    docker ps -a >> /var/log/devopsfetch.log
    lastlog >> /var/log/devopsfetch.log
    sleep 60
  done
}

# Display help message
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -p, --port [port_number]   Display all active ports or detailed information about a specific port"
  echo "  -d, --docker [container]   List Docker images and containers or detailed information about a specific container"
  echo "  -n, --nginx [domain]       Display all Nginx domains and ports or detailed information about a specific domain"
  echo "  -u, --users [username]     List all users and their last login times or detailed information about a specific user"
  echo "  -t, --time [start] [end]   Display activities within a specified time range"
  echo "  -m, --monitor              Start continuous monitoring and logging of server activities"
  echo "  -h, --help                 Show this help message"
}

# Main logic to handle command-line arguments
case $1 in
  -p|--port)
    if [ -n "$2" ]; then
      port_details $2
    else
      list_ports
    fi
    ;;
  -d|--docker)
    if [ -n "$2" ]; then
      container_details $2
    else
      list_docker
    fi
    ;;
  -n|--nginx)
    if [ -n "$2" ]; then
      nginx_details $2
    else
      list_nginx
    fi
    ;;
  -u|--users)
    if [ -n "$2" ]; then
      user_details $2
    else
      list_users
    fi
    ;;
  -t|--time)
    if [ -n "$2" ] && [ -n "$3" ]; then
      time_range $2 $3
    else
      echo "Please specify a valid time range: --time [start] [end]"
    fi
    ;;
  -m|--monitor)
    monitor
    ;;
  -h|--help)
    show_help
    ;;
  *)
    echo "Invalid option. Use -h or --help to see the available options."
    ;;
esac
