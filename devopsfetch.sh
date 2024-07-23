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
    # printf "%-20s %-20s %-50s %-20s %-20s %-30s %-20s\n" "Container ID" "Image" "Command" "Created" "Status" "Ports" "Names"
    if [ -n "$1" ]; then
        log_message "Displaying Docker details for container $1"
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
        log_message "Displaying user login details for $1"
        last -w "$1" | head -n -2 | awk '{ printf "%-15s %-10s %-20s %-20s\n", $1, $2, $4" "$5" "$6, $7 }'
    else
        log_message "Displaying user login details"
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

# # Function to log messages
# log_message() {
#     echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
# }

# # Ensure we have the necessary permissions
# if [ "$EUID" -ne 0 ]; then 
#     echo "Please run as root"
#     exit 1
# fi

# # Function to display active ports and services
# display_ports() {
#     printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n" "Netid" "State" "Recv-Q" "Send-Q" "Local Address:Port" "Peer Address:Port" "Process" "Service"
#     if [ -n "$1" ]; then
#         log_message "Displaying details for port $1"
#         sudo ss -tunlp | grep ":$1 "
#     else
#         log_message "Listing all active ports and services:"
#         sudo ss -tunlp | awk '
#             NR > 1 {
#                 service = $1;
#                 for (i=1; i<=NF; i++) {
#                     if ($i ~ /:/) {
#                         local_address = $i;
#                         peer_address = $(i+1);
#                         process = $(i+2);
#                         break;
#                     }
#                 }
#                 printf "%-8s %-10s %-8s %-8s %-22s %-22s %-20s %-10s\n", $1, $2, $3, $4, local_address, peer_address, process, service;
#             }'
#     fi
# }

# # Function to display Docker images and containers
# display_docker() {
#     # printf "%-20s %-20s %-50s %-20s %-20s %-30s %-20s\n" "Container ID" "Image" "Command" "Created" "Status" "Ports" "Names"
#     if [ -n "$1" ]; then
#         log_message "Displaying details for Docker container $1"
#         docker ps -a --filter "name=$1" --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
#     else
#         log_message "Listing all Docker images and containers:"
#         docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
#     fi
# }

# # Function to display Nginx configurations
# display_nginx() {
#     if [ -n "$1" ]; then
#         log_message "Displaying Nginx configuration for domain $1"
#         domain_config=$(sudo nginx -T 2>/dev/null | awk "/server_name $1/,/}/")
#         if [ -z "$domain_config" ]; then
#             echo "Domain $1 not found in Nginx configuration."
#         else
#             echo "$domain_config"
#         fi
#     else
#         log_message "Listing all Nginx domains and their ports:"
#         printf "%-20s %-10s\n" "Server Name" "Port"
#         sudo nginx -T 2>/dev/null | awk '
#             /server_name/ {
#                 server_name = $2;
#                 getline;
#                 while ($0 !~ /}/) {
#                     if ($0 ~ /listen/) {
#                         port = $2;
#                         gsub(";", "", port);
#                         printf "%-20s %-10s\n", server_name, port;
#                     }
#                     getline;
#                 }
#             }'
#     fi
# }

# # Function to display user logins
# display_users() {
#     printf "%-15s %-10s %-20s %-20s\n" "Username" "Terminal" "Login Time" "Session Duration"
#     if [ -n "$1" ]; then
#         log_message "Displaying details for user $1"
#         last -w "$1" | head -n -2 | awk '{ printf "%-15s %-10s %-20s %-20s\n", $1, $2, $4" "$5" "$6, $7 }'
#     else
#         log_message "Listing all users and their last login times:"
#         last -w | head -n -2 | awk '{ printf "%-15s %-10s %-20s %-20s\n", $1, $2, $4" "$5" "$6, $7 }'
#     fi
# }

# # Function to display help
# display_help() {
#     echo "Usage: $0 [option]"
#     echo "Options:"
#     echo "  -p, --port [port_number]  Display active ports and services, or details for a specific port"
#     echo "  -d, --docker [container_name]  List Docker images and containers, or details for a specific container"
#     echo "  -n, --nginx [domain]  Display Nginx domains and ports, or configuration for a specific domain"
#     echo "  -u, --users [username]  List users and last login times, or details for a specific user"
#     echo "  -m, --monitor  Start monitoring mode"
#     echo "  -h, --help  Display this help message"
# }

# # Function for monitoring mode
# monitor_mode() {
#     log_message "Monitoring mode started"
#     while true; do
#         log_message "Logging active ports and services:"
#         display_ports | tee -a "$LOG_FILE"
        
#         log_message "Logging Docker images and containers:"
#         display_docker | tee -a "$LOG_FILE"
        
#         log_message "Logging Nginx domains and ports:"
#         display_nginx | tee -a "$LOG_FILE"
        
#         log_message "Logging user logins:"
#         display_users | tee -a "$LOG_FILE"
        
#         sleep 300 # Sleep for 5 minutes before next check
#     done
# }

# # Main script logic
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
#     -m|--monitor)
#         monitor_mode
#         ;;
#     -h|--help)
#         display_help
#         ;;
#     *)
#         echo "Invalid option: $1"
#         display_help
#         ;;
# esac

