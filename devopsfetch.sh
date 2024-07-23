#!/bin/bash

LOG_DIR="/var/log/devopsfetch"
LOG_FILE="$LOG_DIR/devopsfetch.log"

# Ensure log directory and file exist
if [ ! -d "$LOG_DIR" ]; then
    sudo mkdir -p $LOG_DIR
fi

if [ ! -f "$LOG_FILE" ]; then
    sudo touch $LOG_FILE
fi

sudo chmod 666 $LOG_FILE

# Function to log messages
log_message() {
    echo "$(date): $1" | sudo tee -a $LOG_FILE > /dev/null
}

# Function to get service name by port
get_service_by_port() {
    local port=$1
    local service=$(sudo ss -tunlp | grep ":$port " | awk '{print $1}')
    echo $service
}

display_ports() {
    log_message "Listing all active ports and services:"
    printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n" "Netid" "State" "Recv-Q" "Send-Q" "Local Address:Port" "Peer Address:Port" "Process" "Service"
    sudo ss -tunlp | awk '
        NR > 1 {
            service = $1;
            for (i=1; i<=NF; i++) {
                if ($i ~ /:/) {
                    local_address = $i;
                    peer_address = $(i+1);
                    process = $(i+2);
                    break;
                }
            }
            printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n", $1, $2, $3, $4, local_address, peer_address, process, service;
        }'
}

display_docker_info() {
    log_message "Listing all Docker images and containers:"
    printf "%-15s %-30s %-20s %-10s %-10s %-20s %-30s\n" "CONTAINER ID" "IMAGE" "COMMAND" "CREATED" "STATUS" "PORTS" "NAMES"
    sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}" | tail -n +2
}

display_nginx_info() {
    log_message "Listing all Nginx domains and their ports:"
    sudo nginx -T 2>/dev/null | grep -E 'server_name|listen' | awk '
        /server_name/ { domain=$2; getline; print domain, $2 }'
}

display_users() {
    log_message "Listing all users and their last login times:"
    printf "%-20s %-8s %-20s %-30s\n" "Username" "Port" "From" "Latest"
    lastlog | tail -n +2 | awk '
        NR > 1 {
            printf "%-20s %-8s %-20s %-30s\n", $1, $2, $3, $4;
        }'
}

display_time_range() {
    log_message "Displaying activities from $1 to $2"
    sudo journalctl --since="$1" --until="$2" | tail -n +2 | awk '
        NR > 1 {
            printf "%-20s %-100s\n", $1, $2;
        }'
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
    echo "  -p, --port                   Display all active ports and services"
    echo "  -d, --docker                 List all Docker images and containers"
    echo "  -n, --nginx                  List all Nginx domains and their ports"
    echo "  -u, --users                  List all users and their last login times"
    echo "  -t, --time [START] [END]     Display activities within a specified time range"
    echo "  -m, --monitor                Start continuous monitoring and logging"
    echo "  -h, --help                   Show this help message"
}

case "$1" in
    -p|--port)
        display_ports
        ;;
    -d|--docker)
        display_docker_info
        ;;
    -n|--nginx)
        display_nginx_info
        ;;
    -u|--users)
        display_users
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

