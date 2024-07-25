#!/bin/bash

# Set the log file path
LOG_FILE="/var/log/monitor.log"

# Ensure the log file exists and is writable
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
fi

# Helper Functions
calculate_max_widths() {
    local data="$1"
    local -n max_lengths_ref=$2  # Using local nameref to reference the array
    while IFS= read -r line; do
        local fields=($line)
        for i in "${!fields[@]}"; do
            local length=${#fields[i]}
            if (( length > max_lengths_ref[i] )); then
                max_lengths_ref[i]=$length
            fi
        done
    done <<< "$data"
}

str_repeat() {
    local char=$1
    local num=$2
    printf "%${num}s" | tr ' ' "$char"
}

log_message() {
    local message="$1"
    echo "[INFO] $(date): $message" | tee -a "$LOG_FILE"
}


display_ports() {
    echo "****************************** ACTIVE PORTS AND SERVICES ******************************"

    # Retrieve port and service information
    ports_services=$(sudo ss -tunlp | awk 'NR>1 {print $1"|" $2"|" $3"|" $4"|" $5"|" $6"|" $7"|" $8}')
    
    # Define maximum column widths
    local max_lengths
    max_lengths=(8 10 8 8 22 22 20 10)

    # Function to create a separator line
    create_separator() {
        local sep=""
        for width in "${max_lengths[@]}"; do
            sep+=$(printf "%${width}s" | tr ' ' '-')
            sep+="+"
        done
        echo "+${sep::-1}+"  # Remove the trailing "+"
    }

    # Header with aligned columns
    header="| Netid    | State       | Recv-Q   | Send-Q   | Local Address:Port           | Peer Address:Port            | Process              | Service     |"
    
    # Print header and separator
    echo "$header"
    echo "$(create_separator)"
    
    # Check if a specific port is requested
    if [ -n "$1" ]; then
        # log_message "Displaying details for port $1"
        sudo ss -tunlp | grep ":$1 " | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" -v max3="${max_lengths[3]}" -v max4="${max_lengths[4]}" -v max5="${max_lengths[5]}" -v max6="${max_lengths[6]}" -v max7="${max_lengths[7]}" '
            { printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4, max4, $5, max5, $6, max6, $7, max7, $8; }'
    else
        # log_message "Listing all active ports and services:"
        sudo ss -tunlp | awk -v max0="${max_lengths[0]}" -v max1="${max_lengths[1]}" -v max2="${max_lengths[2]}" -v max3="${max_lengths[3]}" -v max4="${max_lengths[4]}" -v max5="${max_lengths[5]}" -v max6="${max_lengths[6]}" -v max7="${max_lengths[7]}" '
            NR > 1 { printf "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4, max4, $5, max5, $6, max6, $7, max7, $8; }'
    fi

    # Print the closing line
    echo "$(create_separator)"
    echo "**************************************************************************************"
}


display_docker() {
    local container_name="$1"

    if [ -z "$container_name" ]; then
        echo "****************************** DOCKER STATUS ******************************"
        docker_images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2)
        docker_containers=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2)
        max_image_lengths=(20 20 50 20)
        calculate_max_widths "$docker_images" max_image_lengths
        max_container_lengths=(20 20 20 20)
        calculate_max_widths "$docker_containers" max_container_lengths
        echo "Docker Images:"
        printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_image_lengths[0]}" "REPOSITORY" "${max_image_lengths[1]}" "TAG" "${max_image_lengths[2]}" "IMAGE ID" "${max_image_lengths[3]}" "SIZE"
        printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_image_lengths[0]}")" "$(str_repeat '-' "${max_image_lengths[1]}")" "$(str_repeat '-' "${max_image_lengths[2]}")" "$(str_repeat '-' "${max_image_lengths[3]}")"
        echo "$docker_images" | awk -v max0="${max_image_lengths[0]}" -v max1="${max_image_lengths[1]}" -v max2="${max_image_lengths[2]}" -v max3="${max_image_lengths[3]}" '
        {
            printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4;
        }'
        echo ""
        echo "Docker Containers:"
        printf "| %-*s | %-*s | %-*s | %-*s |\n" "${max_container_lengths[0]}" "NAMES" "${max_container_lengths[1]}" "IMAGE" "${max_container_lengths[2]}" "STATUS" "${max_container_lengths[3]}" "PORTS"
        printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' "${max_container_lengths[0]}")" "$(str_repeat '-' "${max_container_lengths[1]}")" "$(str_repeat '-' "${max_container_lengths[2]}")" "$(str_repeat '-' "${max_container_lengths[3]}")"
        echo "$docker_containers" | awk -v max0="${max_container_lengths[0]}" -v max1="${max_container_lengths[1]}" -v max2="${max_container_lengths[2]}" -v max3="${max_container_lengths[3]}" '
        {
            printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $2, max2, $3, max3, $4;
        }'
        echo "***************************************************************************"
    else
        echo "****************************** DOCKER CONTAINER DETAILS ******************************"
        container_details=$(docker inspect "$container_name" --format "Name: {{.Name}}\nImage: {{.Image}}\nStatus: {{.State.Status}}\nPorts: {{.NetworkSettings.Ports}}")
        echo -e "$container_details" # Use -e to interpret escape sequences
        echo "**************************************************************************************"
    fi
}


display_nginx() {
    local domain="$1"
    
    echo "****************************** NGINX DOMAIN VALIDATION ******************************"
    echo "[INFO] $(date "+%a %b %d %T %Y"): Listing all Nginx domains and their ports:"

    # Define column widths
    local col_width_domain=40
    local col_width_proxy=10
    local col_width_config_file=30

    # Function to create a separator line
    create_separator() {
        local sep1=$(printf "%${col_width_domain}s" | tr ' ' '-')
        local sep2=$(printf "%${col_width_proxy}s" | tr ' ' '-')
        local sep3=$(printf "%${col_width_config_file}s" | tr ' ' '-')
        printf "+%s+%s+%s+\n" "$sep1" "$sep2" "$sep3"
    }

    # Print header
    printf "| %-*s | %-*s | %-*s |\n" \
        "$col_width_domain" "DOMAIN" \
        "$col_width_proxy" "PROXY" \
        "$col_width_config_file" "CONFIGURATION FILE"
    create_separator

    # Fetch and format Nginx configuration details
    if [ -n "$domain" ]; then
        # Display specific domain
        grep -rE "server_name\s+$domain" /etc/nginx/nginx.conf /etc/nginx/sites-enabled/ 2>/dev/null | \
        awk -v w1="$col_width_domain" -v w2="$col_width_proxy" -v w3="$col_width_config_file" \
        '{ 
            split($0, a, ":")
            printf "| %-*s | %-*s | %-*s |\n", w1, a[2], w2, "N/A", w3, "N/A" 
        }'
    else
        # List all domains
        grep -rE "server_name" /etc/nginx/nginx.conf /etc/nginx/sites-enabled/ 2>/dev/null | \
        awk -v w1="$col_width_domain" -v w2="$col_width_proxy" -v w3="$col_width_config_file" \
        '{ 
            split($0, a, ":")
            printf "| %-*s | %-*s | %-*s |\n", w1, a[2], w2, "N/A", w3, "N/A" 
        }'
    fi

    # Print closing line
    create_separator
    echo "**************************************************************************************"
}



# display_nginx() {
#     local domain="$1"
    
#     echo "****************************** NGINX DOMAIN VALIDATION ******************************"
#     echo "[INFO] $(date "+%a %b %d %T %Y"): Listing all Nginx domains and their ports:"

#     # Define column widths
#     local col_width_domain=40
#     local col_width_proxy=10
#     local col_width_config_file=30

#     # Function to create a separator line
#     create_separator() {
#         local sep1=$(printf "%${col_width_domain}s" | tr ' ' '-')
#         local sep2=$(printf "%${col_width_proxy}s" | tr ' ' '-')
#         local sep3=$(printf "%${col_width_config_file}s" | tr ' ' '-')
#         printf "+%s+%s+%s+\n" "$sep1" "$sep2" "$sep3"
#     }

#     # Print header
#     printf "| %-*s | %-*s | %-*s |\n" \
#         "$col_width_domain" "DOMAIN" \
#         "$col_width_proxy" "PROXY" \
#         "$col_width_config_file" "CONFIGURATION FILE"
#     create_separator

#     # Fetch and format Nginx configuration details
#     if [ -n "$domain" ]; then
#         # Filtering specific domain
#         sudo grep -E "server_name\s+$domain|root" /etc/nginx/nginx.conf /etc/nginx/sites-enabled/* 2>/dev/null \
#             | awk -v w1="$col_width_domain" -v w2="$col_width_proxy" -v w3="$col_width_config_file" \
#             '{ printf "| %-*s | %-*s | %-*s |\n", w1, $1, w2, "N/A", w3, "N/A" }'
#     else
#         # List all domains
#         sudo grep -E 'server_name' /etc/nginx/nginx.conf /etc/nginx/sites-enabled/* 2>/dev/null \
#             | awk -v w1="$col_width_domain" -v w2="$col_width_proxy" -v w3="$col_width_config_file" \
#             '{ printf "| %-*s | %-*s | %-*s |\n", w1, $1, w2, "N/A", w3, "N/A" }'
#     fi

#     # Print closing line
#     create_separator
#     echo "**************************************************************************************"
# }



display_users() {
    local username="$1"
    echo "****************************** USER DETAILS ******************************"

    if [ -n "$username" ]; then
        # Display details for a specific user
        user_info=$(getent passwd "$username")
        if [ -z "$user_info" ]; then
            echo "Error: User $username not found."
            return 1
        fi

        IFS=':' read -r uname password uid gid full_name home_dir shell <<< "$user_info"

        printf "| %-*s | %-*s | %-*s | %-*s |\n" 20 "Username" 20 "Full Name" 30 "Home Directory" 20 "Shell"
        printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' 20)" "$(str_repeat '-' 20)" "$(str_repeat '-' 30)" "$(str_repeat '-' 20)"
        printf "| %-*s | %-*s | %-*s | %-*s |\n" 20 "$uname" 20 "$full_name" 30 "$home_dir" 20 "$shell"

        echo ""
        echo "| User            | Login Time           | Logout Time          | Duration             |"
        echo "| --------------- | -------------------- | -------------------- | -------------------- |"

        # Fetch user login information using the `last` command
        login_info=$(last -F "$username" | head -n -2)

        if [ -z "$login_info" ]; then
            echo "| No login records found for $username |"
        else
            echo "$login_info" | awk -v max_lengths="14 20 20 20" '
            {
                user = $1
                login_time = $4 " " $5 " " $6 " " $7
                logout_time = $9 " " $10 " " $11 " " $12
                duration = $13

                if ($8 == "still") {
                    logout_time = "still logged in"
                    duration = $10
                }

                printf "| %-*s | %-*s | %-*s | %-*s |\n", 14, user, 20, login_time, 20, logout_time, 20, duration
            }'
        fi

    else
        # List all users
        echo "Listing all users and their last login times:"
        printf "| %-*s | %-*s | %-*s | %-*s |\n" 20 "Username" 20 "Full Name" 30 "Home Directory" 20 "Shell"
        printf "| %s | %s | %s | %s |\n" "$(str_repeat '-' 20)" "$(str_repeat '-' 20)" "$(str_repeat '-' 30)" "$(str_repeat '-' 20)"

        # Fetch all users information
        getent passwd | awk -F: -v max0=20 -v max1=20 -v max2=30 -v max3=20 '
        {
            printf "| %-*s | %-*s | %-*s | %-*s |\n", max0, $1, max1, $5, max2, $6, max3, $7
        }'

        echo ""
        echo "| User            | Login Time           | Logout Time          | Duration             |"
        echo "| --------------- | -------------------- | -------------------- | -------------------- |"

        # Fetch login information for all users
        last -F | awk '
        {
            user = $1
            login_time = $4 " " $5 " " $6 " " $7
            logout_time = $9 " " $10 " " $11 " " $12
            duration = $13

            if ($8 == "still") {
                logout_time = "still logged in"
                duration = $10
            }

            printf "| %-*s | %-*s | %-*s | %-*s |\n", 14, user, 20, login_time, 20, logout_time, 20, duration
        }'
    fi

    echo "***************************************************************************"
}

display_time_range() {
    local start_date="$1"
    local end_date="${2:-$(date '+%Y-%m-%d %H:%M:%S')}"
    local log_file="${LOG_FILE:-/var/log/monitor.log}"  # Default to /var/log/monitor.log if LOG_FILE is not set

    if [[ -z "$start_date" || -z "$end_date" ]]; then
        echo "Error: Both start and end dates are required."
        return 1
    fi

    # Convert start and end dates to UNIX timestamps
    local start_timestamp=$(date -d "$start_date" +%s 2>/dev/null)
    local end_timestamp=$(date -d "$end_date" +%s 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo "Error: Invalid date format. Use YYYY-MM-DD HH:MM:SS."
        return 1
    fi

    echo "****************************** SYSTEM LOGS ******************************"
    echo "Displaying logs from $start_date to $end_date:"

    # Check if the log file exists
    if [[ ! -f "$log_file" ]]; then
        echo "Error: Log file $log_file does not exist."
        return 1
    fi

    # Read log file line by line
    local log_entry
    while IFS= read -r log_entry; do
        # Extract date from log entry
        local log_date=$(echo "$log_entry" | awk -F'[][]' '{print $2}' | awk '{print $1, $2, $3, $4}')
        local log_timestamp=$(date -d "$log_date" +%s 2>/dev/null)

        if [[ $? -ne 0 ]]; then
            continue
        fi

        # Check if log entry is within the date range
        if [[ "$log_timestamp" -ge "$start_timestamp" && "$log_timestamp" -le "$end_timestamp" ]]; then
            echo "$log_entry"
        fi
    done < "$log_file"

    if [[ ! -s "$log_file" ]]; then
        echo "-- No entries --"
    fi

    echo "***************************************************************************"
}


monitor_mode() {
    log_message "Monitoring mode started"
    while true; do
        # log_message "Logging active ports and services:"
        display_ports | tee -a "$LOG_FILE"
        
        # log_message "Logging Docker images and containers:"
        display_docker | tee -a "$LOG_FILE"
        
        # log_message "Logging Nginx domains and ports:"
        display_nginx | tee -a "$LOG_FILE"
        
        # log_message "Logging user logins:"
        display_users | tee -a "$LOG_FILE"
        
        sleep 120 # Sleep for 2 minutes before next check
    done
}

# Parse command-line options
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
    -t|--time)
        display_time_range "$2" "$3"
        ;;
    -m|--monitor)
        monitor_mode
        ;;
    -h|--help)
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  -p, --port <port>        Display details for a specific port"
        echo "  -d, --docker [container_name]    List Docker images and containers, or details for a specific container"
        echo "  -n, --nginx [domain]     Display Nginx configuration, or for a specific domain"
        echo "  -u, --users [username]   List users and last login times, or details for a specific user"
        echo "  -t, --time <start> <end> Display logs within a specific time range"
        echo "  -m, --monitor            Monitor mode to display all sections periodically"
        echo "  -h, --help               Display this help message"
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        ;;
esac


