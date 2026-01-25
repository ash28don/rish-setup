#!/usr/bin/env bash

# ashchange.sh - Email & Password change for CPM1 / CPM2 accounts
#
# Dependencies:
#   Termux (Android): pkg install curl jq -y
#   iSH (iOS):        apk add curl jq bash
#
# Author: Ash

# ---------------- ENV DETECT ----------------
if command -v pkg >/dev/null 2>&1; then
    ENV="Termux (Android)"
elif command -v apk >/dev/null 2>&1; then
    ENV="iSH (iOS)"
else
    ENV="Unknown"
fi

clear
echo "====================================="
echo "        ASH CHANGE TOOL"
echo "    Email & Password Manager"
echo "====================================="
echo "[*] Environment: $ENV"
echo

# ---------------- GAME SELECT ----------------
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

# ---------------- CREDENTIALS ----------------
read -p "Email: " EMAIL
read -p "Password: " PASSWORD
echo

echo
echo "[*] Logging in..."

# ---------------- LOGIN ----------------
LOGIN_RESPONSE=$(curl -s -X POST \
"https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=$API_KEY" \
-H "Content-Type: application/json" \
-d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")

ID_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.idToken')
LOCAL_EMAIL=$(echo "$LOGIN_RESPONSE" | jq -r '.email')
ERROR_MSG=$(echo "$LOGIN_RESPONSE" | jq -r '.error.message')

if [ -z "$ID_TOKEN" ] || [ "$ID_TOKEN" = "null" ]; then
    echo "[!] Login failed: $ERROR_MSG"
    exit 1
fi

echo "[✓] Logged in as $LOCAL_EMAIL on $GAME_NAME"

# ---------------- MENU LOOP ----------------
while true; do
    echo
    echo "1) Change Email"
    echo "2) Change Password"
    echo "3) Exit"
    read -p "Select an option: " opt
    echo

    case "$opt" in
        1)
            read -p "New Email: " NEW_EMAIL

            CHANGE=$(curl -s -X POST \
            "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"idToken\":\"$ID_TOKEN\",\"email\":\"$NEW_EMAIL\",\"returnSecureToken\":true}")

            UPDATED_EMAIL=$(echo "$CHANGE" | jq -r '.email')
            NEW_TOKEN=$(echo "$CHANGE" | jq -r '.idToken')
            ERROR_MSG=$(echo "$CHANGE" | jq -r '.error.message')

            if [ -n "$UPDATED_EMAIL" ] && [ "$UPDATED_EMAIL" != "null" ]; then
                ID_TOKEN="$NEW_TOKEN"
                LOCAL_EMAIL="$UPDATED_EMAIL"
                echo "[✓] Email changed to $LOCAL_EMAIL"
            else
                echo "[!] Failed: $ERROR_MSG"
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
            ERROR_MSG=$(echo "$CHANGE" | jq -r '.error.message')

            if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ]; then
                ID_TOKEN="$NEW_TOKEN"
                echo "[✓] Password changed successfully!"
            else
                echo "[!] Failed: $ERROR_MSG"
            fi
            ;;

        3)
            echo "Exiting..."
            exit 0
            ;;

        *)
            echo "[!] Invalid option"
            ;;
    esac
done