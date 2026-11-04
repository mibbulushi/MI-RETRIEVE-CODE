/**
 * Fail-closed read-access policy for the future MI MEMORY API adapter.
 *
 * All identity, link, project-owner, and grant fields must come from trusted
 * authentication claims and server-side records. Never build this context from
 * MCP tool arguments or other caller-controlled data.
 *
 * This helper does not authenticate users, fetch projects, or write audit logs.
 */
export function evaluateProjectReadAccess(context = {}) {
  const {
    authenticatedOwnerId,
    requestingAccountId,
    projectId,
    projectOwnerId,
    accountLink,
    shareGrant,
  } = context;

  const deny = (reason) => ({ allowed: false, reason });

  if (!authenticatedOwnerId) {
    return deny("AUTHENTICATION_REQUIRED");
  }
  if (!requestingAccountId) {
    return deny("LINKED_ACCOUNT_REQUIRED");
  }
  if (!projectId) {
    return deny("PROJECT_ID_REQUIRED");
  }
  if (!projectOwnerId || projectOwnerId !== authenticatedOwnerId) {
    return deny("PROJECT_OWNER_MISMATCH");
  }

  if (
    !accountLink ||
    accountLink.ownerId !== authenticatedOwnerId ||
    accountLink.accountId !== requestingAccountId ||
    accountLink.status !== "active"
  ) {
    return deny("ACCOUNT_LINK_INACTIVE_OR_MISMATCHED");
  }
  if (
    !Array.isArray(accountLink.permissions) ||
    !accountLink.permissions.includes("project:read")
  ) {
    return deny("ACCOUNT_READ_PERMISSION_REQUIRED");
  }

  if (
    !shareGrant ||
    shareGrant.ownerId !== authenticatedOwnerId ||
    shareGrant.projectId !== projectId ||
    shareGrant.accountId !== requestingAccountId
  ) {
    return deny("EXPLICIT_PROJECT_SHARE_REQUIRED");
  }
  if (shareGrant.status !== "active") {
    return deny("PROJECT_SHARE_INACTIVE");
  }
  if (
    !Array.isArray(shareGrant.scopes) ||
    !shareGrant.scopes.includes("project:read")
  ) {
    return deny("PROJECT_READ_SCOPE_REQUIRED");
  }
  if (shareGrant.expiresAt !== null && shareGrant.expiresAt !== undefined) {
    const expiry = Date.parse(shareGrant.expiresAt);
    if (!Number.isFinite(expiry) || expiry <= Date.now()) {
      return deny("PROJECT_SHARE_EXPIRED_OR_INVALID");
    }
  }

  return { allowed: true, reason: "AUTHORIZED" };
}
