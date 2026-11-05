
# MI Project Password Protection

## 1. Purpose
Allow a project owner to protect a shared project with an optional password.

## 2. Owner Controls
- Password protection is optional.
- The owner can enable or disable password protection.
- The owner can set, change, or remove the password.
- Only the authenticated project owner can manage this setting.
- Minimum password length: 8 characters.

## 3. Recipient Access
When password protection is enabled:
1. Recipient enters the Share Code.
2. Recipient enters the project password.
3. The server verifies the password.
4. If correct, the shared project becomes available.
5. If incorrect, no project content or attachments are returned.

When password protection is disabled, existing Share Codes continue to work as before.

## 4. Security Requirements
- Never store passwords as plain text.
- Store only secure password hashes using a suitable password-hashing algorithm such as Argon2id or bcrypt.
- Verify passwords on the server.
- Apply rate limits to failed password attempts.
- Use a generic error message for failed access.
- Protect project text, images, and files equally.
- Do not allow direct attachment links to bypass password protection.
- Remove or securely replace any old public access method that bypasses password verification.
- Keep password information separate from account login credentials.

## 5. Existing Projects
Existing projects without password protection must continue working.

Password protection must not unexpectedly disable existing Share Codes.

## 6. Owner Permissions
Only the authenticated project owner can:
- Enable password protection.
- Set a password.
- Change a password.
- Remove a password.

## 7. Important Limitation
Revoking access cannot retrieve copies that recipients have already downloaded or captured.

## 8. Implementation Status
This document describes the planned feature only.

The feature is NOT implemented or active until the database, secure server functions, website interface, attachment access, and security tests have all been completed.

## 9. Testing Requirements
- Correct password allows access.
- Incorrect password does not return project data.
- Existing unprotected Share Codes still work.
- Images and files remain protected.
- Non-owners cannot change password settings.
- Repeated failed attempts are rate-limited.
