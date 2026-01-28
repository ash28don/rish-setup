#!/usr/bin/env sh

# ASH CHANGE TOOL
# Email & Password manager for CPM1 / CPM2
# Compatible with Termux & iSH
# Requires: curl, jq

while true; do
    clear
    echo "====================================="
    echo "        ASH CHANGE TOOL"
    echo "    Email & Password Manager"
    echo "====================================="
    echo
    echo "1) Login"
    echo "2) Exit"
    echo
    printf "Select option: "
    read mainChoice

    case "$mainChoice" in
        1)
            ;;
        2)
            echo "[*] Exiting script..."
            sleep 1
            exit 0
            ;;
        *)
            echo "[!] Invalid option"
            sleep 1
            continue
            ;;
    esac

    clear
    echo "Select Game:"
    echo "1) CPM1"
    echo "2) CPM2"
    echo
    printf "Choice: "
    read gameChoice

    if [ "$gameChoice" = "1" ]; then
        API_KEY="AIzaSyBW1ZbMiUeDZHYUO2bY8Bfnf5rRgrQGPTM"
        GAME_NAME="CPM1"
    elif [ "$gameChoice" = "2" ]; then
        API_KEY="AIzaSyCQDz9rgjgmvmFkvVfmvr2-7fT4tfrzRRQ"
        GAME_NAME="CPM2"
    else
        echo "[!] Invalid game selection"
        sleep 1
        continue
    fi

    echo
    printf "Email: "
    read EMAIL
    printf "Password: "
    read PASSWORD

    echo
    echo "[*] Logging in..."

    LOGIN_RESPONSE=$(curl -s -X POST \
        "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=$API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")

    ID_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.idToken')
    LOCAL_EMAIL=$(echo "$LOGIN_RESPONSE" | jq -r '.email')

    if [ -z "$ID_TOKEN" ] || [ "$ID_TOKEN" = "null" ]; then
        echo "[!] Login failed"
        echo "Reason: $(echo "$LOGIN_RESPONSE" | jq -r '.error.message')"
        sleep 2
        continue
    fi

    echo "[✓] Logged in as $LOCAL_EMAIL ($GAME_NAME)"
    sleep 1

    while true; do
        clear
        echo "====================================="
        echo " Logged in: $LOCAL_EMAIL"
        echo " Game: $GAME_NAME"
        echo "====================================="
        echo
        echo "1) Change Email"
        echo "2) Change Password"
        echo "3) Logout"
        echo "4) Exit Script"
        echo
        printf "Select option: "
        read opt

        case "$opt" in
            1)
                printf "New Email: "
                read NEW_EMAIL

                CHANGE=$(curl -s -X POST \
                    "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$API_KEY" \
                    -H "Content-Type: application/json" \
                    -d "{\"idToken\":\"$ID_TOKEN\",\"email\":\"$NEW_EMAIL\",\"returnSecureToken\":true}")

                UPDATED_EMAIL=$(echo "$CHANGE" | jq -r '.email')
                NEW_TOKEN=$(echo "$CHANGE" | jq -r '.idToken')

                if [ -n "$UPDATED_EMAIL" ] && [ "$UPDATED_EMAIL" != "null" ]; then
                    ID_TOKEN="$NEW_TOKEN"
                    LOCAL_EMAIL="$UPDATED_EMAIL"
                    echo "[✓] Email updated successfully"
                else
                    echo "[!] Failed: $(echo "$CHANGE" | jq -r '.error.message')"
                fi
                sleep 2
                ;;
            2)
                printf "New Password: "
                read NEW_PASS

                CHANGE=$(curl -s -X POST \
                    "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$API_KEY" \
                    -H "Content-Type: application/json" \
                    -d "{\"idToken\":\"$ID_TOKEN\",\"password\":\"$NEW_PASS\",\"returnSecureToken\":true}")

                NEW_TOKEN=$(echo "$CHANGE" | jq -r '.idToken')

                if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ]; then
                    ID_TOKEN="$NEW_TOKEN"
                    echo "[✓] Password changed successfully"
                else
                    echo "[!] Failed: $(echo "$CHANGE" | jq -r '.error.message')"
                fi
                sleep 2
                ;;
            3)
                echo "[*] Logged out"
                sleep 1
                break
                ;;
            4)
                echo "[*] Exiting script..."
                sleep 1
                exit 0
                ;;
            *)
                echo "[!] Invalid option"
                sleep 1
                ;;
        esac
    done
done