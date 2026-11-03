# MI-RETRIEVE-CODE

**MI-RETRIEVE-CODE** is a project to help people save, organize, retrieve, and share useful information using unique reference codes.

## Project goal

Build one easy-to-use platform with an integrated MI Assistant. The long-term plan is a complete AI ecosystem with user and administrator controls.

## Current prototype

- Save a title and text in the current browser.
- Generate a unique reference code.
- Retrieve saved text in the same browser.

**Important:** The current prototype uses browser local storage. Codes do not yet retrieve information across different devices or users. Do not store passwords, private documents, or sensitive information in this prototype.

## Command directory

These are planned command names. A command is not considered active until its feature is implemented and tested.

| Command | Planned purpose |
| --- | --- |
| `/create-project` | Start a new project |
| `/save-project` | Save content |
| `/retrieve-project` | Retrieve content by code |
| `/update-project` | Update saved content |
| `/share-project` | Share content with permitted people |
| `/revoke-access` | Revoke future access |
| `/search-project` | Search saved content |
| `/summarize` | Summarize supplied content |
| `/translate` | Translate supplied content |
| `/research` | Organize research |
| `/write` | Draft written content |
| `/create-code` | Generate a reference code |
| `/analyze-file` | Analyze an uploaded file |
| `/generate-report` | Prepare a report |

## Development roadmap

1. Improve the single-page website and make it mobile-friendly.
2. Add a secure cloud database so users can retrieve content across devices.
3. Add accounts, ownership, permissions, and access controls.
4. Add sharing options, expiry settings, and access revocation.
5. Build the MI Assistant command interface.
6. Add AI-powered tools only when an appropriate service and safe configuration are available.
7. Test the platform, privacy controls, backups, and accessibility.

## Important access limitation

Revoking access can prevent future access through this platform, but cannot guarantee deletion of copies that someone has already downloaded, copied, or captured.

## Cost and security principles

- Prefer free tools and services while the project is being developed.
- Never publish API keys, passwords, or private credentials in website code or this repository.
- Explain clearly when a feature is a prototype, planned, or fully working.
