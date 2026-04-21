---
name: google-drive
description: 'Fetch Google Sheets, Docs, and other Drive content via CLI using existing OAuth credentials. USE FOR: reading spreadsheets, downloading CSV data, accessing Google Docs. ALWAYS use when user shares a Google Sheets/Docs link or asks to read spreadsheet data. READ-ONLY — does not modify Drive content.'
---

# Google Drive CLI Access

Read Google Sheets and Docs content using OAuth credentials stored locally. No MCP server or GCP project access needed.

## Credentials

- **Path**: `~/.config/google-oauth/token.json`
- **Type**: `authorized_user` (client_id, client_secret, refresh_token)
- **Scopes**: documents, drive, spreadsheets, script.external_request
- **Account**: on-running.com (work account)

## Fetch a Spreadsheet as CSV

Extract the spreadsheet ID and gid from the URL pattern:
`https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit?gid={GID}`

Then run:

```python
python3 -c "
import json, urllib.request, urllib.parse

with open('$HOME/.config/google-oauth/token.json') as f:
    creds = json.load(f)

data = urllib.parse.urlencode({
    'client_id': creds['client_id'],
    'client_secret': creds['client_secret'],
    'refresh_token': creds['refresh_token'],
    'grant_type': 'refresh_token'
}).encode()

req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
resp = json.loads(urllib.request.urlopen(req).read())
token = resp['access_token']

sheet_id = '{SPREADSHEET_ID}'
gid = '{GID}'
url = f'https://docs.google.com/spreadsheets/d/{sheet_id}/export?format=csv&gid={gid}'
req = urllib.request.Request(url, headers={'Authorization': f'Bearer {token}'})
print(urllib.request.urlopen(req).read().decode('utf-8'))
"
```

## Fetch a Google Doc as Plain Text

Extract doc ID from: `https://docs.google.com/document/d/{DOC_ID}/edit`

Use export URL: `https://docs.google.com/document/d/{DOC_ID}/export?format=txt`

Same auth pattern — replace the URL and remove gid logic.

## Troubleshooting

- **401 Unauthorized**: Refresh token may have expired. Re-run the OAuth flow that originally created the token.
- **403 Forbidden**: The authenticated account doesn't have access to the document. Check sharing permissions.
- **Token file missing**: Expected at `~/.config/google-oauth/token.json`. Was originally created by a Google Docs MCP setup.
