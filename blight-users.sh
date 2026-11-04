#!/bin/bash
# Identify and remove orphaned system users on Arch Linux
# Usage: ./blight-users.sh [--dry-run]
#
# Test: Create orphaned user (will be removed):
#   sudo useradd -r -u 1500 -s /usr/sbin/nologin -d /var/lib/testorphan1 testorphan1
#
# Test: Create protected user (has files, won't be removed):
#   sudo useradd -r -u 1501 -s /usr/sbin/nologin -d /var/lib/testorphan2 testorphan2
#   sudo mkdir -p /var/lib/testorphan2 && sudo touch /var/lib/testorphan2/file
#   sudo chown 1501:1501 /var/lib/testorphan2
#
# Cleanup testorphan2 (protected by files, manual removal needed):
#   sudo userdel testorphan2 && sudo rm -rf /var/lib/testorphan2

# Validate arguments: only accept 0 args or exactly "--dry-run"
if [[ $# -gt 1 ]]; then
    echo "Error: Too many arguments." >&2
    echo "Usage: $0 [--dry-run]" >&2
    exit 1
fi

if [[ $# -eq 1 && "$1" != "--dry-run" ]]; then
    echo "Error: Invalid argument '$1'. Only '--dry-run' is accepted." >&2
    echo "Usage: $0 [--dry-run]" >&2
    exit 1
fi

DRY_RUN=0
[[ "$1" == "--dry-run" ]] && DRY_RUN=1

[[ $DRY_RUN -eq 1 ]] && echo "*** DRY-RUN MODE ***"
echo "=== Generating Package Map ==="

# Extract system users (UID 100-65533, non-home directories)
mapfile -t system_users < <(awk -F: '$3 >= 100 && $3 < 65534 && $6 !~ /^\/home\// {print $1}' /etc/passwd | sort)

# Users that must match a specific package (user→package binding)
# e.g., git→git, tor→tor, fakeuser→mytestpkg
declare -A required_package_match=(
    ["git"]="git"
    ["tor"]="tor"
)
declare -A user_packages
declare -A package_map

# Map each system user to its owning package
while read -r package filepath; do
    for user in "${system_users[@]}"; do
        if [[ -z "${user_packages[$user]}" ]] && [[ "$filepath" == *"/$user"* ]]; then
            # Strict matching for users with required package bindings
            if [[ -v required_package_match[$user] ]]; then
                [[ "$package" == "${required_package_match[$user]}" ]] && user_packages["$user"]="$package"
            else
                # Loose matching for others (preserves legitimate mismatches)
                user_packages["$user"]="$package"
            fi
        fi
    done
done < <(pacman -Ql)

# Track users whose mapped package doesn't exist
for user in "${!user_packages[@]}"; do
    pacman -Q "$user" &>/dev/null || package_map["$user"]="${user_packages[$user]}"
done

echo "Found ${#package_map[@]} package mismatches"
[[ ${#package_map[@]} -gt 0 ]] && for user in "${!package_map[@]}"; do
    echo "  $user → ${package_map[$user]}"
done

echo -e "\n=== Checking for Orphaned System Users ==="
orphaned_count=0

# Check each system user: orphaned if no package AND no owned files
while IFS=: read username _ uid _ _ _ _; do
    [[ ! "$uid" =~ ^[0-9]+$ ]] || (( uid < 100 || uid >= 65534 )) && continue
    
    file_count=$(find / -uid "$uid" -type f -not -path "/home/*" 2>/dev/null | wc -l)
    pkg="${package_map[$username]:-$username}"
    
    pacman -Q "$pkg" &>/dev/null && continue
    [[ $file_count -eq 0 ]] || continue
    
    ((orphaned_count++))
    group=$(awk -F: -v u="$uid" '$3 == u {print $1}' /etc/group)
    echo -e "\nFound orphaned user: $username (UID: $uid)"
    [[ -n "$group" ]] && echo "Associated group: $group"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY-RUN] Would remove user: $username"
        [[ -n "$group" ]] && echo "[DRY-RUN] Would remove group: $group"
    else
        read -p "Remove user $username? (y/n) " -n1 response < /dev/tty
        echo
        [[ $response == y ]] && sudo userdel "$username" && \
            [[ -n "$group" ]] && getent group "$group" &>/dev/null && sudo groupdel "$group"
    fi
done < /etc/passwd

[[ $orphaned_count -eq 0 ]] && echo "No orphaned users found."
[[ $DRY_RUN -eq 1 ]] && echo -e "\n*** END DRY-RUN ***"
