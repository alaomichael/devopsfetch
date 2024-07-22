#!/bin/bash

# Functions for system information retrieval

function show_ports() {
    ss -tuln
}

function show_port_info() {
    local port=$1
    ss -tulnp | grep ":$port "
}

function show_docker_info() {
    docker images
    docker ps -a
}

function show_container_info() {
    local container_name=$1
    docker inspect $container_name
}

function show_nginx_info() {
    nginx -T 2>/dev/null | grep 'server_name\|listen'
}

function show_domain_info() {
    local domain=$1
    nginx -T 2>/dev/null | awk -v domain="$domain" '
    /server_name/ {sn=0}
    /server_name.*'"$domain"'/ {sn=1}
    sn {print}
    '
}

function show_users() {
    lastlog
}

function show_user_info() {
    local username=$1
    lastlog -u $username
}

function show_time_range() {
    local start_time=$1
    local end_time=$2
    journalctl --since="$start_time" --until="$end_time"
}

function monitor_and_log() {
    while true; do
        date >> /var/log/devopsfetch.log
        show_ports >> /var/log/devopsfetch.log
        show_docker_info >> /var/log/devopsfetch.log
        show_nginx_info >> /var/log/devopsfetch.log
        show_users >> /var/log/devopsfetch.log
        sleep 3600  # Run every hour
    done
}

function show_help() {
    echo "Usage: devopsfetch [OPTIONS]"
    echo "Options:"
    echo "  -p, --port [port_number]   Display all active ports or detailed info about a specific port"
    echo "  -d, --docker [container]   List Docker images and containers or detailed info about a specific container"
    echo "  -n, --nginx [domain]       Display all Nginx domains and ports or detailed info about a specific domain"
    echo "  -u, --users [username]     List all users and their last login times or detailed info about a specific user"
    echo "  -t, --time [start] [end]   Display activities within a specified time range"
    echo "  -m, --monitor              Start continuous monitoring and logging"
    echo "  -h, --help                 Show this help message"
}

if [[ $1 == "-h" || $1 == "--help" ]]; then
    show_help
    exit 0
fi

case "$1" in
    -p|--port)
        if [[ -n $2 ]]; then
            show_port_info $2
        else
            show_ports
        fi
        ;;
    -d|--docker)
        if [[ -n $2 ]]; then
            show_container_info $2
        else
            show_docker_info
        fi
        ;;
    -n|--nginx)
        if [[ -n $2 ]]; then
            show_domain_info $2
        else
            show_nginx_info
        fi
        ;;
    -u|--users)
        if [[ -n $2 ]]; then
            show_user_info $2
        else
            show_users
        fi
        ;;
    -t|--time)
        if [[ -n $2 && -n $3 ]]; then
            show_time_range $2 $3
        else
            echo "Error: Please provide both start and end time."
        fi
        ;;
    -m|--monitor)
        monitor_and_log
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage instructions."
        ;;
esac
