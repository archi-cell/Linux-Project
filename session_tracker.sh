#!/bin/bash

LOG_FILE="./logs/session_tracker.log"
mkdir -p ./logs

if [[ "$EUID" -ne 0 ]]; then
    dialog --msgbox "Please run this script as root!" 8 40 --colors
    clear
    exit 1
fi

log_action() {
    local action="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $(whoami) | $action" >> "$LOG_FILE"
}

view_active_session() {
    ACTIVE_SESSIONS=$(w | awk 'NR==1 || NR==2 || NR>2 {printf "%-10s %-8s %-12s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5, $6}')
    dialog --title "Active Sessions" --msgbox "USER       TTY     FROM         LOGIN     IDLE      JCPU\n\n$ACTIVE_SESSIONS" 20 70 --colors
    log_action "Viewed active sessions"
}

search_login_history() {
    USERNAME=$(dialog --inputbox "Enter username to search login history:" 8 50 3>&1 1>&2 2>&3 3>&-)
    if id "$USERNAME" &>/dev/null; then
        LOGIN_HISTORY=$(last "$USERNAME" | head -n 10 | awk '{printf "%-15s %-10s %-20s %-20s\n", $1, $2, $3, $4}')
        dialog --title "Login History for $USERNAME" \
               --msgbox "USER            TTY        HOST                 TIME\n\n$LOGIN_HISTORY" 20 70 --colors
        log_action "Searched login history for user: $USERNAME"
    else
        dialog --msgbox "User '$USERNAME' does not exist!" 8 40 --colors
        log_action "Attempted to search non-existent user: $USERNAME"
    fi
}

generate_login_report() {
    REPORT_FILE="./logs/login_report_$(date '+%Y%m%d_%H%M%S').txt"
    last > "$REPORT_FILE"
    dialog --title "Report Generated" --msgbox "Session report saved at: $REPORT_FILE" 8 50 --colors
    log_action "Generated session report: $REPORT_FILE"
}

view_failed_logins() {
    FAILED_LOGINS=$(lastb | head -n 10 | awk '{printf "%-15s %-10s %-20s %-15s\n", $1, $2, $3, $4}')
    dialog --title "Failed Login Attempts" \
           --msgbox "USER            TTY        HOST                 TIME\n\n$FAILED_LOGINS" 20 70
    log_action "Viewed failed login attempts"
}

monitor_user_live() {
    USERNAME=$(dialog --inputbox "Enter username to monitor:" 8 50 3>&1 1>&2 2>&3 3>&-)
    if id "$USERNAME" &>/dev/null; then
        log_action "Started monitoring user: $USERNAME"
        # Replace with your preferred terminal emulator if needed
        gnome-terminal -- bash -c "watch -n 5 'w | grep ^$USERNAME'; exec bash"
    else
        dialog --msgbox "User '$USERNAME' does not exist!" 8 50
        log_action "Attempted to monitor non-existent user: $USERNAME"
    fi
}

clear_log_file() {
    > "$LOG_FILE"
    dialog --msgbox "Session tracker log file cleared." 8 40
    log_action "Cleared session tracker log file"
}

view_log_file() {
    LOG_CONTENT=$(tail -n 20 "$LOG_FILE")
    dialog --title "Recent Actions Log" --msgbox "$LOG_CONTENT" 20 70
    log_action "Viewed tracker log file"
}

# Main menu loop
while true; do
    CHOICE=$(dialog --clear --backtitle "Ubuntu User Session Tracker" \
        --title "Main Menu" \
        --menu "Choose an option:" 20 60 10 \
        1 "View Active Sessions" \
        2 "Search Login History" \
        3 "Generate Session Report" \
        4 "View Failed Login Attempts" \
        5 "Monitor a Specific User Live" \
        6 "Clear Tracker Log File" \
        7 "View Tracker Log File" \
        8 "Exit" \
        3>&1 1>&2 2>&3 3>&-)

    case "$CHOICE" in
        1) view_active_session ;;
        2) search_login_history ;;
        3) generate_login_report ;;
        4) view_failed_logins ;;
        5) monitor_user_live ;;
        6) clear_log_file ;;
        7) view_log_file ;;
        8)
            log_action "Exited Session Tracker"
            clear
            exit 0
            ;;
        *)
            dialog --msgbox "Invalid choice, please try again." 8 40
            ;;
    esac
done
