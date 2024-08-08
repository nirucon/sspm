#!/bin/bash

# Function to display help info
display_help() {
    echo "ESC: quit | arrow up/down: navigate | enter: confirm install/uninstall selected package"
}

# Function to search for packages
search_packages() {
    local search_term="$1"
    case "$PACKAGE_MANAGER" in
        pacman)
            search_result=$(pacman -Ss "$search_term" | awk '{print $1" "$2" "$3}')
            ;;
        aur)
            search_result=$(aur search "$search_term" | awk '{print $1" "$2" "$3}')
            ;;
        apt)
            search_result=$(apt search "$search_term" | awk '{print $1" "$2" "$3}')
            ;;
        xbps)
            search_result=$(xbps-query -Rs "$search_term" | awk '{print $1" "$2" "$3}')
            ;;
        dnf)
            search_result=$(dnf search "$search_term" | awk '{print $1" "$2" "$3}')
            ;;
        *)
            echo "Unsupported package manager!"
            exit 1
            ;;
    esac
    echo "$search_result"
}

# Function to check if a package is installed
is_installed() {
    local package_name="$1"
    case "$PACKAGE_MANAGER" in
        pacman)
            pacman -Q "$package_name" &> /dev/null
            ;;
        aur)
            aur list_installed | grep -q "$package_name"
            ;;
        apt)
            dpkg -l | grep -q "$package_name"
            ;;
        xbps)
            xbps-query -l | grep -q "$package_name"
            ;;
        dnf)
            dnf list installed | grep -q "$package_name"
            ;;
    esac
    return $?
}

# Function to install a package
install_package() {
    local package_name="$1"
    case "$PACKAGE_MANAGER" in
        pacman)
            sudo pacman -S "$package_name"
            ;;
        aur)
            aur install "$package_name"
            ;;
        apt)
            sudo apt install "$package_name"
            ;;
        xbps)
            sudo xbps-install "$package_name"
            ;;
        dnf)
            sudo dnf install "$package_name"
            ;;
    esac
}

# Function to uninstall a package
uninstall_package() {
    local package_name="$1"
    case "$PACKAGE_MANAGER" in
        pacman)
            sudo pacman -R "$package_name"
            ;;
        aur)
            aur remove "$package_name"
            ;;
        apt)
            sudo apt remove "$package_name"
            ;;
        xbps)
            sudo xbps-remove "$package_name"
            ;;
        dnf)
            sudo dnf remove "$package_name"
            ;;
    esac
}

# Determine the package manager
if command -v pacman &> /dev/null; then
    PACKAGE_MANAGER="pacman"
elif command -v aur &> /dev/null; then
    PACKAGE_MANAGER="aur"
elif command -v apt &> /dev/null; then
    PACKAGE_MANAGER="apt"
elif command -v xbps-query &> /dev/null; then
    PACKAGE_MANAGER="xbps"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf"
else
    echo "No supported package manager found!"
    exit 1
fi

# Clear terminal and set up UI
clear
echo "sspm - Shit Simple Package Manager"
echo "Search for packages: "
echo
display_help

# Main loop
while true; do
    # Search for packages
    read -p "Search: " search_term
    search_results=$(search_packages "$search_term")
    
    # Display results with fzf
    selected_package=$(echo "$search_results" | fzf --height 45% --border --info=inline --preview-window=down:45% --preview="echo {}")

    # If a package is selected, prompt for installation/uninstallation
    if [ -n "$selected_package" ]; then
        package_name=$(echo "$selected_package" | awk '{print $1}')
        echo "Selected package: $package_name"
        
        if is_installed "$package_name"; then
            read -p "Package is already installed. Do you want to uninstall $package_name? (Y/n) " confirm
            if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])$|^$ ]]; then
                uninstall_package "$package_name"
            else
                echo "Aborted."
            fi
        else
            read -p "Do you want to install $package_name? (Y/n) " confirm
            if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])$|^$ ]]; then
                install_package "$package_name"
            else
                echo "Aborted."
            fi
        fi
    else
        echo "No package selected."
    fi

    # Exit on ESC
    read -rsn1 key
    if [[ $key == $'\e' ]]; then
        echo "Exiting..."
        break
    fi
done
