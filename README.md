# Synchronize Office 365 to IMAP

![ImapSync Logo](img/imapsync_pixel.png)

A tool to synchronize emails from Office 365 to an IMAP server using OAuth2 authentication and ImapSync.

## Prerequisites

- Python 3.x
- [imapsync](https://imapsync.lamiral.info/#install)
- Azure Application with IMAP permissions

## Installation

1. Clone this repository
2. Install Python dependencies:
```sh
pip install -r requirements.txt
```

## Configuration

Create a `.env` file with the following parameters or pass them as command line arguments:

```ini
O365_IMAP_HOST='outlook.office365.com'
O365_IMAP_USER='user@domain.com'
CLIENT_ID='your-azure-client-id'
TENANT_ID='your-azure-tenant-id'
CLIENT_SECRET='your-azure-client-secret'
IMAP_HOST='target.imap.server'
IMAP_USER='user@target.com'
IMAP_PASSWORD='target-password'
```

## Usage

Run the synchronization script:

```sh
./oauth2_imapsync.sh
```

Or with command line arguments:

```sh
./oauth2_imapsync.sh \
  --o365-host outlook.office365.com \
  --o365-user user@domain.com \
  --client-id your-client-id \
  --tenant-id your-tenant-id \
  --client-secret your-client-secret \
  --imap-host target.server \
  --imap-user user@target.com \
  --imap-password "password"
```

The script will:
1. Obtain an OAuth2 token from Office 365
2. Store the token in a file
3. Synchronize emails using imapsync
4. Preserve folder structure and avoid duplicates

## Features

- OAuth2 authentication for Office 365
- Automatic token management
- Cross-duplicate detection
- Folder mapping
- No email deletion on source (--noexpunge)

## Files

- `oauth2_imapsync.sh`: Main synchronization script
- `get_imap_oauth2_office365.py`: OAuth2 token generator
- `.env`: Configuration file
- `requirements.txt`: Python dependencies
