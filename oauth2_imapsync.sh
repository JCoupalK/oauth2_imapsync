#!/bin/bash

# Usage function
usage() {
  echo "Usage: $0"
  echo ""
  echo "  --o365-host, -oh        Office365 IMAP host (e.g., outlook.office365.com)"
  echo "  --o365-user, -ou        Office365 email address (e.g., user@domain.com)"
  echo "  --client-id, -i         Azure App Client ID"
  echo "  --tenant-id, -t         Azure App Tenant ID"
  echo "  --client-secret, -s     Azure App Client Secret"
  echo "  --imap-host, -ih        Target IMAP host (e.g., 192.168.1.2)"
  echo "  --imap-user, -iu        Target IMAP email address (e.g., user@domain.com)"
  echo "  --imap-password, -p     Target IMAP password"
  echo ""
  echo "You can also provide the above parameters in a .env file:"
  echo "  
    O365_IMAP_HOST='outlook.office365.com'
    O365_IMAP_USER='user@domain.com'
    CLIENT_ID='my-client-id'
    TENANT_ID='my-tenant-id'
    CLIENT_SECRET='my-client-secret'
    IMAP_HOST='imap.targetserver.com'
    IMAP_USER='user@targetserver.com'
    IMAP_PASSWORD='password123'"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --o365-host|-oh) O365_IMAP_HOST="$2"; shift 2 ;;
    --o365-user|-ou) O365_IMAP_USER="$2"; shift 2 ;;
    --client-id|-i) CLIENT_ID="$2"; shift 2 ;;
    --tenant-id|-t) TENANT_ID="$2"; shift 2 ;;
    --client-secret|-s) CLIENT_SECRET="$2"; shift 2 ;;
    --imap-host|-ih) IMAP_HOST="$2"; shift 2 ;;
    --imap-user|-iu) IMAP_USER="$2"; shift 2 ;;
    --imap-password|-p) IMAP_PASSWORD="$2"; shift 2 ;;
    *) usage ;;
  esac
done

# If a .env file is provided, load the values from it
if [[ -f "$PWD/.env" ]]; then
  source "$PWD/.env"
  echo -e "Loaded environment variables from .env file.\n"
fi

# Validate required arguments if no .env file is provided
if [[ -z "$O365_IMAP_HOST" || -z "$O365_IMAP_USER" || -z "$CLIENT_ID" || -z "$TENANT_ID" || -z "$CLIENT_SECRET" || -z "$IMAP_HOST" || -z "$IMAP_USER" || -z "$IMAP_PASSWORD" ]]; then
  usage
fi

# Check if imapsync is installed
if ! command -v imapsync &> /dev/null; then
  echo -e '\e[31m\nError: imapsync is not installed!\e[0m'
  echo "To install imapsync, follow the instructions at: https://imapsync.lamiral.info/#install"
  exit 1
fi

# Run the Python script to get the OAuth2 token
pip3 install -r "$PWD/requirements.txt" &> /dev/null
python3 "$PWD/get_imap_oauth2_office365.py" \
  --client-id "$CLIENT_ID" \
  --tenant-id "$TENANT_ID" \
  --client-secret "$CLIENT_SECRET" \
  --email-user "$O365_IMAP_USER"

# Check if the Python script failed
if [[ $? -ne 0 ]]; then
  echo -e '\e[31m\nError: Failed to execute get_imap_oauth2_office365.py.\e[0m'  # Red for failure
  exit 1
fi

# Check if the token was successfully created
TOKEN_PATH="$PWD/tokens/oauth2_tokens_${O365_IMAP_USER}.txt"
if [[ ! -f "$TOKEN_PATH" ]]; then
  echo -e '\e[31m\nError: OAuth2 token file not found at \"$TOKEN_PATH\".\e[0m'
  exit 1
fi

# Run imapsync with the generated token
imapsync \
  --host1 "$O365_IMAP_HOST" \
  --authmech1 "xoauth2" \
  --user1 "$O365_IMAP_USER" \
  --password1 'ignored' \
  --oauthaccesstoken1 "$TOKEN_PATH" \
  --host2 "$IMAP_HOST" \
  --user2 "$IMAP_USER" \
  --password2 "$IMAP_PASSWORD" \
  --skipcrossduplicates \
  --automap \
  --noexpunge

# Check the exit status of the imapsync command
if [[ $? -eq 0 ]]; then
  echo -e '\e[32m\nSuccess: IMAP sync completed successfully!\e[0m'  # Green for success
  exit 0
else
  echo -e '\e[31m\nError: IMAP sync failed.\e[0m'  # Red for failure
  exit 1
fi
