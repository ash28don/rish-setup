#!/data/data/com.termux/files/usr/bin/bash

# ashchange.sh - Email & Password change for CPM1/CPM2 accounts
# Dependencies: curl, jq
# Install in Termux if not installed: pkg install curl jq -y

echo "====================================="
echo "        ASH CHANGE TOOL"
echo "    Email & Password Manager"
echo "====================================="

read -p "Select Game (1=CPM1, 2=CPM2): " gameChoice
if [ "$gameChoice" = "1" ]; then
    API_KEY="AIzaSyBW1ZbMiUeDZHYUO2bY8Bfnf5rRgrQGPTM"
    GAME_NAME="CPM1"
elif [ "$gameChoice" = "2" ]; then
    API_KEY="AIzaSyCQDz9rgjgmvmFkvVfmvr2-7fT4tfrzRRQ"
    GAME_NAME="CPM2"
else
    echo "[!] Invalid choice"
    exit 1
fi

read -p "Email: " EMAIL
read -p "Password: " PASSWORD
echo

echo "[*] Logging in..."

# Login
LOGIN_RESPONSE=$(curl -s -X POST "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=$API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")

ID_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.idToken')
LOCAL_EMAIL=$(echo "$LOGIN_RESPONSE" | jq -r '.email')

if [ "$ID_TOKEN" = "null" ] || [ -z "$ID_TOKEN" ]; then
    echo "[!] Login failed: $(echo "$LOGIN_RESPONSE" | jq -r '.error.message')"
    exit 1
fi

echo "[✓] Logged in as $LOCAL_EMAIL on $GAME_NAME"

while true; do
    echo
    echo "1) Change Email"
    echo "2) Change Password"
    echo "3) Exit"
    read -p "Select an option: " opt

    if [ "$opt" = "1" ]; then
        read -p "New Email: " NEW_EMAIL
        CHANGE=$(curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$API_KEY" \
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

    elif [ "$opt" = "2" ]; then
        read -p "New Password: " NEW_PASS
        echo
        CHANGE=$(curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"idToken\":\"$ID_TOKEN\",\"password\":\"$NEW_PASS\",\"returnSecureToken\":true}")
        NEW_TOKEN=$(echo "$CHANGE" | jq -r '.idToken')
        if [ "$NEW_TOKEN" != "null" ] && [ -n "$NEW_TOKEN" ]; then
            ID_TOKEN="$NEW_TOKEN"
            echo "[✓] Password changed successfully!"
        else
            echo "[!] Failed: $(echo "$CHANGE" | jq -r '.error.message')"
        fi

    elif [ "$opt" = "3" ]; then
        echo "Exiting..."
        exit 0
    else
        echo "[!] Invalid option"
    fi
done