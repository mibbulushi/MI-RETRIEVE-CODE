# MI Scheduled Project Release

## Purpose
Allow any project owner (student, teacher, doctor, engineer, scientist, project manager, or other creator) to prepare a project now and have it shared automatically with a selected audience at a chosen future date and time.

## User workflow
1. Create or open a project.
2. Choose **Schedule Share / Issue Later**.
3. Select the intended audience: a specific person, an existing group, or a class/team.
4. Set the release date, time, and delivery timezone.
5. Choose the access scope: view only or download where permitted; optionally set an expiry date.
6. Review a release summary and confirm.
7. The project remains private until the scheduled release time.
8. At release time, the system activates the share access and notifies the selected recipients where notification delivery is configured.
9. The owner can view release status, recipient list, and access activity; cancel or reschedule before release; and revoke access after release.

## Important behavior and safeguards
- Do not expose scheduled projects or attachments before the release time.
- Validate that the owner is authorized to share every selected project and attachment.
- Show the exact audience, release date/time, timezone, and access scope before confirmation.
- Avoid public-by-default sharing. A project is shared only with the selected people/group.
- Record who scheduled, changed, cancelled, or released a project and when.
- Handle failed releases visibly; retry safely without creating duplicate shares or notifications.
- If a recipient is not registered, provide a controlled invitation/link flow only after the owner confirms the recipient details.
- Revoking access prevents future platform access but cannot remove copies already downloaded or captured externally.
- Do not promise delivery if the scheduler, notification provider, or recipient contact method is unavailable.

## Implementation plan
1. Database: add a scheduled-release record linked to the project, owner, audience/group, release timestamp, timezone, status, and access settings. Apply strict Row Level Security.
2. Backend scheduler: use a trusted server-side scheduled worker/cron or Supabase Edge Function. Never rely on a browser tab being open to release projects.
3. Release worker: atomically activate the intended share access at/after the scheduled timestamp, with idempotency and an audit log.
4. Notifications: add email/in-app notifications after successful release; report delivery failures separately from sharing status.
5. UI: add scheduling controls, a confirmation summary, pending/sent/failed/cancelled status, and cancel/reschedule controls.
6. Tests: verify private-before-release, correct recipients-after-release, timezone handling, expiry, cancellation, duplicate prevention, and unauthorized-access denial.

## Current status
Design recorded only. This feature is NOT implemented yet. The existing app's immediate Share Code flow remains separate until the scheduled-release backend and UI are implemented and tested.
