#!/bin/bash

LOG_DIR="/var/log/devopsfetch"
LOG_FILE="$LOG_DIR/devopsfetch.log"

# Create log directory if it doesn't exist
sudo mkdir -p $LOG_DIR
sudo touch $LOG_FILE
sudo chmod 666 $LOG_FILE

# Function to log messages
log_message() {
    echo "$(date): $1" | sudo tee -a $LOG_FILE > /dev/null
}

display_ports() {
    if [ -z "$1" ]; then
        log_message "Listing all active ports and services:"
        echo "Netid  State  Recv-Q  Send-Q   Local Address:Port   Peer Address:Port  Process"
        sudo ss -tunlp
    else
        log_message "Displaying details for port: $1"
        sudo lsof -i :$1
    fi
}

display_docker_info() {
    if [ -z "$1" ]; then
        log_message "Listing all Docker images and containers:"
        sudo docker ps -a
        sudo docker images
    else
        log_message "Displaying details for Docker container: $1"
        sudo docker inspect $1
    fi
}

display_nginx_info() {
    if [ -z "$1" ]; then
        log_message "Listing all Nginx domains and their ports:"
        sudo nginx -T 2>/dev/null | grep 'server_name\|listen'
    else
        log_message "Displaying Nginx configuration for domain: $1"
        sudo nginx -T 2>/dev/null | awk "/server_name[[:space:]]$1/,/}/"
    fi
}

display_users() {
    if [ -z "$1" ]; then
        log_message "Listing all users and their last login times:"
        echo -e "Username\t\tPort\tFrom\t\tLatest"
        lastlog
    else
        log_message "Displaying details for user: $1"
        echo -e "Username\t\tPort\tFrom\t\tLatest"
        lastlog -u $1
    fi
}

display_time_range() {
    log_message "Displaying activities from $1 to $2"
    sudo journalctl --since="$1" --until="$2"
}

continuous_monitoring() {
    log_message "Starting continuous monitoring and logging"
    while true; do
        display_ports >> $LOG_FILE
        display_docker_info >> $LOG_FILE
        display_nginx_info >> $LOG_FILE
        display_users >> $LOG_FILE
        sleep 60
    done
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --port [PORT_NUMBER]     Display all active ports or details for a specific port"
    echo "  -d, --docker [CONTAINER]     List all Docker images and containers or details for a specific container"
    echo "  -n, --nginx [DOMAIN]         List all Nginx domains and their ports or details for a specific domain"
    echo "  -u, --users [USERNAME]       List all users and their last login times or details for a specific user"
    echo "  -t, --time [START] [END]     Display activities within a specified time range"
    echo "  -m, --monitor                Start continuous monitoring and logging"
    echo "  -h, --help                   Show this help message"
}

case "$1" in
    -p|--port)
        display_ports $2
        ;;
    -d|--docker)
        display_docker_info $2
        ;;
    -n|--nginx)
        display_nginx_info $2
        ;;
    -u|--users)
        display_users $2
        ;;
    -t|--time)
        display_time_range $2 $3
        ;;
    -m|--monitor)
        continuous_monitoring
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        ;;
esac
