import os
import imaplib
import msal
import argparse
import logging


# Ensure the tokens directory exists
cwd = os.getcwd()
os.makedirs(f'{cwd}/tokens', exist_ok=True)


# Parse CLI arguments
parser = argparse.ArgumentParser(
    description='Get IMAP OAuth2 Authentication Token')
parser.add_argument('-c', '--client-id', required=True,
                    help='Azure App Client ID')
parser.add_argument('-t', '--tenant-id', required=True,
                    help='Azure App Tenant ID')
parser.add_argument('-s', '--client-secret', required=True,
                    help='Azure App Client Secret')
parser.add_argument('-e', '--email-user', required=True,
                    help='Email address of the user')
parser.add_argument(
    '-d', '--debug',
    help="Print lots of debugging statements",
    action="store_const", dest="loglevel", const=logging.DEBUG,
    default=logging.WARNING,
)
args = parser.parse_args()
logging.basicConfig(level=args.loglevel)

# Authenticate with MSAL
app = msal.ConfidentialClientApplication(
    args.client_id,
    authority=f'https://login.microsoftonline.com/{args.tenant_id}',
    client_credential=f"{args.client_secret}"
)

result = app.acquire_token_for_client(
    scopes=['https://outlook.office365.com/.default'])

if 'access_token' not in result:
    print("Failed to acquire token:", result.get(
        'error_description', 'Unknown error'))
    exit(1)


def generate_auth_string(user, token):
    return 'user=%s\1auth=Bearer %s\1\1' % (user, token)


# Save token to file
token_path = f'{cwd}/tokens/oauth2_tokens_{args.email_user}.txt'
with open(token_path, 'w') as token_file:
    token_file.write(result['access_token'])

# IMAP connection
mailserver = 'outlook.office365.com'
imapport = 993
M = imaplib.IMAP4_SSL(mailserver, imapport)
M.debug = 4
M.authenticate('XOAUTH2', lambda x: generate_auth_string(
    args.email_user, result['access_token']))

try:
    print(
        f"Oauth2 token created at: {token_path}\n")
    exit(0)
except Exception as e:
    print(f"An error occurred: {e}\n", exec_info=True)
    exit(1)
