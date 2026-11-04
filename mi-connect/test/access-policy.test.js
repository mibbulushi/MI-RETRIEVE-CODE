import test from "node:test";
import assert from "node:assert/strict";
import { evaluateProjectReadAccess } from "../src/access-policy.js";

const validContext = () => ({
  authenticatedOwnerId: "mi-owner-1",
  requestingAccountId: "linked-ai-account-2",
  projectId: "project-42",
  projectOwnerId: "mi-owner-1",
  accountLink: {
    ownerId: "mi-owner-1",
    accountId: "linked-ai-account-2",
    status: "active",
    permissions: ["project:read"],
  },
  shareGrant: {
    ownerId: "mi-owner-1",
    accountId: "linked-ai-account-2",
    projectId: "project-42",
    status: "active",
    scopes: ["project:read"],
    expiresAt: "2099-01-01T00:00:00.000Z",
  },
});

test("denies when authentication context is missing", () => {
  const result = evaluateProjectReadAccess();
  assert.deepEqual(result, { allowed: false, reason: "AUTHENTICATION_REQUIRED" });
});

test("allows only an active linked account with an explicit project read grant", () => {
  assert.deepEqual(evaluateProjectReadAccess(validContext()), {
    allowed: true,
    reason: "AUTHORIZED",
  });
});

test("denies a revoked linked account", () => {
  const context = validContext();
  context.accountLink.status = "revoked";
  assert.equal(evaluateProjectReadAccess(context).reason, "ACCOUNT_LINK_INACTIVE_OR_MISMATCHED");
});

test("denies an account without read permission", () => {
  const context = validContext();
  context.accountLink.permissions = [];
  assert.equal(evaluateProjectReadAccess(context).reason, "ACCOUNT_READ_PERMISSION_REQUIRED");
});

test("denies when no explicit project share exists", () => {
  const context = validContext();
  context.shareGrant = null;
  assert.equal(evaluateProjectReadAccess(context).reason, "EXPLICIT_PROJECT_SHARE_REQUIRED");
});

test("denies a grant for a different account", () => {
  const context = validContext();
  context.shareGrant.accountId = "another-account";
  assert.equal(evaluateProjectReadAccess(context).reason, "EXPLICIT_PROJECT_SHARE_REQUIRED");
});

test("denies a grant for a different project", () => {
  const context = validContext();
  context.shareGrant.projectId = "private-project-elsewhere";
  assert.equal(evaluateProjectReadAccess(context).reason, "EXPLICIT_PROJECT_SHARE_REQUIRED");
});

test("denies a revoked project share", () => {
  const context = validContext();
  context.shareGrant.status = "revoked";
  assert.equal(evaluateProjectReadAccess(context).reason, "PROJECT_SHARE_INACTIVE");
});

test("denies write-only or missing share scopes", () => {
  const context = validContext();
  context.shareGrant.scopes = ["project:write"];
  assert.equal(evaluateProjectReadAccess(context).reason, "PROJECT_READ_SCOPE_REQUIRED");
});

test("denies expired or invalid share expiry", () => {
  const expired = validContext();
  expired.shareGrant.expiresAt = "2000-01-01T00:00:00.000Z";
  assert.equal(evaluateProjectReadAccess(expired).reason, "PROJECT_SHARE_EXPIRED_OR_INVALID");

  const invalid = validContext();
  invalid.shareGrant.expiresAt = "not-a-date";
  assert.equal(evaluateProjectReadAccess(invalid).reason, "PROJECT_SHARE_EXPIRED_OR_INVALID");
});

test("denies projects not owned by the authenticated MI workspace", () => {
  const context = validContext();
  context.projectOwnerId = "different-owner";
  assert.equal(evaluateProjectReadAccess(context).reason, "PROJECT_OWNER_MISMATCH");
});
