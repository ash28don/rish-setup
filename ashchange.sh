#!/data/data/com.termux/files/usr/bin/bash

# ashchange.sh - Email & Password change for CPM1/CPM2 accounts
# Dependencies: curl, jq

while true; do
    clear
    echo "====================================="
    echo "        ASH CHANGE TOOL"
    echo "    Email & Password Manager"
    echo "====================================="

    # -------- GAME SELECT --------
    read -p "Select Game (1=CPM1, 2=CPM2): " gameChoice

    if [ "$gameChoice" = "1" ]; then
        API_KEY="AIzaSyBW1ZbMiUeDZHYUO2bY8Bfnf5rRgrQGPTM"
        GAME_NAME="CPM1"
    elif [ "$gameChoice" = "2" ]; then
        API_KEY="AIzaSyCQDz9rgjgmvmFkvVfmvr2-7fT4tfrzRRQ"
        GAME_NAME="CPM2"
    else
        echo "[!] Invalid choice"
        sleep 1
        continue
    fi

    # -------- LOGIN --------
    echo
    read -p "Email: " EMAIL
    read -p "Password: " PASSWORD
    echo
    echo "[*] Logging in..."

    LOGIN_RESPONSE=$(curl -s -X POST \
        "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=$API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")

    ID_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.idToken')
    LOCAL_EMAIL=$(echo "$LOGIN_RESPONSE" | jq -r '.email')

    if [ "$ID_TOKEN" = "null" ] || [ -z "$ID_TOKEN" ]; then
        echo "[!] Login failed: $(echo "$LOGIN_RESPONSE" | jq -r '.error.message')"
        sleep 2
        continue
    fi

    echo "[✓] Logged in as $LOCAL_EMAIL on $GAME_NAME"

    # -------- ACCOUNT MENU --------
    while true; do
        echo
        echo "1) Change Email"
        echo "2) Change Password"
        echo "3) Logout / New Account"
        read -p "Select an option: " opt

        case "$opt" in
            1)
                read -p "New Email: " NEW_EMAIL
                CHANGE=$(curl -s -X POST \
                    "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$API_KEY" \
                    -H "Content-Type: application/json" \
                    -d "{\"idToken\":\"$ID_TOKEN\",\"email\":\"$NEW_EMAIL\",\"returnSecureToken\":true}")

                UPDATED_EMAIL=$(echo "$CHANGE" | jq -r '.email')
                NEW_TOKEN=$(echo "$CHANGE" | jq -r '.idToken')

                if [ "$UPDATED_EMAIL" != "null" ] && [ -n "$UPDATED_EMAIL" ]; then
                    ID_TOKEN="$NEW_TOKEN"
                    LOCAL_EMAIL="$UPDATED_EMAIL"
                    echo "[✓] Email changed to $LOCAL_EMAIL"
                else
                    echo "[!] Failed: $(echo "$CHANGE" | jq -r '.error.message')"
                fi
                ;;
            2)
                read -p "New Password: " NEW_PASS
                echo
                CHANGE=$(curl -s -X POST \
                    "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$API_KEY" \
                    -H "Content-Type: application/json" \
                    -d "{\"idToken\":\"$ID_TOKEN\",\"password\":\"$NEW_PASS\",\"returnSecureToken\":true}")

                NEW_TOKEN=$(echo "$CHANGE" | jq -r '.idToken')

                if [ "$NEW_TOKEN" != "null" ] && [ -n "$NEW_TOKEN" ]; then
                    ID_TOKEN="$NEW_TOKEN"
                    echo "[✓] Password changed successfully!"
                else
                    echo "[!] Failed: $(echo "$CHANGE" | jq -r '.error.message')"
                fi
                ;;
            3)
                echo "[*] Logging out..."
                ID_TOKEN=""
                LOCAL_EMAIL=""
                EMAIL=""
                PASSWORD=""
                sleep 1
                break
                ;;
            *)
                echo "[!] Invalid option"
                ;;
        esac
    done
done