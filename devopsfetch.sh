#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Ensure we have the necessary permissions
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Function to display active ports and services
display_ports() {
    printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n" "Netid" "State" "Recv-Q" "Send-Q" "Local Address:Port" "Peer Address:Port" "Process" "Service"
    if [ -n "$1" ]; then
        log_message "Displaying details for port $1"
        sudo ss -tunlp | grep ":$1 "
    else
        log_message "Listing all active ports and services:"
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
    fi
}

# Function to display Docker images and containers
display_docker() {
    printf "%-20s %-20s %-50s %-20s %-20s %-30s %-20s\n" "Container ID" "Image" "Command" "Created" "Status" "Ports" "Names"
    if [ -n "$1" ]; then
        log_message "Displaying details for Docker container $1"
        docker ps -a --filter "name=$1" --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
    else
        log_message "Listing all Docker images and containers:"
        docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
    fi
}

# Function to display Nginx configurations
display_nginx() {
    if [ -n "$1" ]; then
        log_message "Displaying Nginx configuration for domain $1"
        domain_config=$(sudo nginx -T 2>/dev/null | awk "/server_name $1/,/}/")
        if [ -z "$domain_config" ]; then
            echo "Domain $1 not found in Nginx configuration."
        else
            echo "$domain_config"
        fi
    else
        log_message "Listing all Nginx domains and their ports:"
        printf "%-20s %-10s\n" "Server Name" "Port"
        sudo nginx -T 2>/dev/null | awk '
            /server_name/ {
                server_name = $2;
                getline;
                while ($0 !~ /}/) {
                    if ($0 ~ /listen/) {
                        port = $2;
                        gsub(";", "", port);
                        printf "%-20s %-10s\n", server_name, port;
                    }
                    getline;
                }
            }'
    fi
}

# Function to display user logins
display_users() {
    printf "%-15s %-10s %-20s %-20s\n" "Username" "Terminal" "Login Time" "Session Duration"
    if [ -n "$1" ]; then
        log_message "Displaying details for user $1"
        last -w "$1" | head -n -2 | awk '{ printf "%-15s %-10s %-20s %-20s\n", $1, $2, $4" "$5" "$6, $7 }'
    else
        log_message "Listing all users and their last login times:"
        last -w | head -n -2 | awk '{ printf "%-15s %-10s %-20s %-20s\n", $1, $2, $4" "$5" "$6, $7 }'
    fi
}

# Function to display help
display_help() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  -p, --port [port_number]  Display active ports and services, or details for a specific port"
    echo "  -d, --docker [container_name]  List Docker images and containers, or details for a specific container"
    echo "  -n, --nginx [domain]  Display Nginx domains and ports, or configuration for a specific domain"
    echo "  -u, --users [username]  List users and last login times, or details for a specific user"
    echo "  -m, --monitor  Start monitoring mode"
    echo "  -h, --help  Display this help message"
}

# Function for monitoring mode
monitor_mode() {
    log_message "Monitoring mode started"
    while true; do
        log_message "Logging active ports and services:"
        display_ports | tee -a "$LOG_FILE"
        
        log_message "Logging Docker images and containers:"
        display_docker | tee -a "$LOG_FILE"
        
        log_message "Logging Nginx domains and ports:"
        display_nginx | tee -a "$LOG_FILE"
        
        log_message "Logging user logins:"
        display_users | tee -a "$LOG_FILE"
        
        sleep 300 # Sleep for 5 minutes before next check
    done
}

# Main script logic
case "$1" in
    -p|--port)
        display_ports "$2"
        ;;
    -d|--docker)
        display_docker "$2"
        ;;
    -n|--nginx)
        display_nginx "$2"
        ;;
    -u|--users)
        display_users "$2"
        ;;
    -m|--monitor)
        monitor_mode
        ;;
    -h|--help)
        display_help
        ;;
    *)
        echo "Invalid option: $1"
        display_help
        ;;
esac



# #!/bin/bash

# LOG_FILE="/var/log/devopsfetch.log"

# log_message() {
#     echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
# }

# display_ports() {
#     if [ -n "$1" ]; then
#         log_message "Displaying details for port $1"
#         printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n" "Netid" "State" "Recv-Q" "Send-Q" "Local Address:Port" "Peer Address:Port" "Process" "Service"
#         sudo ss -tunlp | grep ":$1 "
#     else
#         log_message "Listing all active ports and services:"
#         printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n" "Netid" "State" "Recv-Q" "Send-Q" "Local Address:Port" "Peer Address:Port" "Process" "Service"
#         sudo ss -tunlp | awk '
#         BEGIN { 
#             printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n", "Netid", "State", "Recv-Q", "Send-Q", "Local Address:Port", "Peer Address:Port", "Process", "Service"
#         }
#         NR > 1 {
#             service = $1;
#             local_address = $5;
#             peer_address = $6;
#             process = $7;
#             printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n", $1, $2, $3, $4, local_address, peer_address, process, service;
#         }'
#     fi
# }

# display_docker() {
#     if [ -n "$1" ]; then
#         log_message "Displaying details for container $1"
#         printf "%-12s %-20s %-40s %-20s %-15s %-25s %-20s\n" "Container ID" "Image" "Command" "Created" "Status" "Ports" "Names"
#         docker ps -a --filter "name=$1" --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
#     else
#         log_message "Listing all Docker images and containers:"
#         printf "%-12s %-20s %-40s %-20s %-15s %-25s %-20s\n" "Container ID" "Image" "Command" "Created" "Status" "Ports" "Names"
#         docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
#     fi
# }

# display_nginx() {
#     if [ -n "$1" ]; then
#         log_message "Displaying details for Nginx domain $1"
#         sudo nginx -T 2>/dev/null | awk -v domain="$1" '
#         BEGIN {
#             printf "%-10s %-25s\n", "Port", "Server Name"
#         }
#         /server_name/ && $0 ~ domain {
#             while (getline && !/}/) {
#                 if ($1 == "listen") {
#                     port = $2
#                 }
#                 if ($1 == "server_name") {
#                     server_name = $2
#                 }
#             }
#             printf "%-10s %-25s\n", port, server_name
#             exit
#         }'
#     else
#         log_message "Listing all Nginx domains and their ports:"
#         sudo nginx -T 2>/dev/null | awk '
#         BEGIN {
#             printf "%-25s\n", "Server Name"
#         }
#         /server_name/ {
#             gsub(/;/,"")
#             printf "%-25s\n", $2
#         }'
#     fi
# }

# display_users() {
#     if [ -n "$1" ]; then
#         log_message "Displaying details for user $1"
#         printf "%-15s %-10s %-20s %-15s\n" "Username" "Terminal" "Login Time" "Session Duration"
#         last -F -w $1 | awk '{ print $1, $2, $4 " " $5 " " $6, $7 }'
#     else
#         log_message "Listing all users and their last login times:"
#         printf "%-15s %-10s %-20s %-15s\n" "Username" "Terminal" "Login Time" "Session Duration"
#         last -F -w | awk '
#         BEGIN { 
#             printf "%-15s %-10s %-20s %-15s\n", "Username", "Terminal", "Login Time", "Session Duration"
#         }
#         { print $1, $2, $4 " " $5 " " $6, $7 }'
#     fi
# }

# display_help() {
#     echo "Usage: $0 [option] [argument]"
#     echo "Options:"
#     echo "  -p, --port       Display active ports and services. Provide port number for specific port details."
#     echo "  -d, --docker     List Docker images and containers. Provide container name for specific container details."
#     echo "  -n, --nginx      List Nginx domains and ports. Provide domain name for specific domain details."
#     echo "  -u, --users      List users and their last login times. Provide username for specific user details."
#     echo "  -t, --time       Display activities within a specified time range."
#     echo "  -h, --help       Display this help message."
# }

# case "$1" in
#     -p|--port)
#         display_ports "$2"
#         ;;
#     -d|--docker)
#         display_docker "$2"
#         ;;
#     -n|--nginx)
#         display_nginx "$2"
#         ;;
#     -u|--users)
#         display_users "$2"
#         ;;
#     -t|--time)
#         log_message "Displaying activities within time range $2"
#         ;;
#     -h|--help)
#         display_help
#         ;;
#     *)
#         echo "Invalid option: $1"
#         display_help
#         ;;
# esac



