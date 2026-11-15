# ADR-24: People vs. accounts, one rotating invite link, owner removal

- **Status:** accepted (owner decision 2026-11-15; amends P6-T04/T05, refines #89)
- **Date:** 2026-11-15

## Context

Typical first use: someone creates a group on holiday, adds Peter, Bob and Jonas, enters the first
expense immediately and drops a link into the WhatsApp group. Nobody else has installed the app yet.
Splitting must not wait for anyone to join.

## Decision

1. **Two independent layers.**
   - **People** (`members`, synced) are who expenses are split between. They exist offline, without an account.
   - **Accounts** (`group_memberships`, server-only) are who may read/write the group.
   - An account *connects* to a person on join ("Wer bist du?") or later, which unlocks that person's
     PayPal/IBAN for settlement and targets push notifications at expenses involving that person.
2. **A person may have several accounts** (a couple paying from a joint account is one person).
   Drop `unique (group_id, member_id)` on `group_memberships`. An account connects to at most one
   person per group. `members.user_id` becomes a non-authoritative "first connected account" hint.
3. **One link per group, no expiry.** Anyone with the link can join. `create_invite` (renamed in UI to
   "Neuen Link erstellen") revokes every other active invite of the group in the same transaction, so
   creating a new link is the kill switch for a leaked one. Links no longer expire after 7 days; a
   link pasted into a chat must keep working for latecomers.
4. **Owner role.** `group_memberships.role in ('owner','member')`, server-authoritative (never the
   synced, client-set `groups.created_by`). The bootstrap membership is `owner`. Only the owner may
   rotate the link and remove accounts. Removing an account deletes its membership (access ends);
   the person and their expenses stay, and the person can be reconnected. If the owner deletes
   their data, ownership passes to the oldest remaining membership.
5. **Wording.** Users only ever see **"Personen"** in a group. A connected person shows a small
   "verbunden" badge. There is no separate noun for accounts, and none for "debtors": the same
   person can pay and owe. Code keeps `members` / `memberships`.

## Consequences

- `join_group` claim check changes from "person already claimed" to "this account already
  connected to another person". Error `member_already_claimed` disappears. `membership_already_linked`
  stays.
- New RPCs `remove_membership(membership_id)` (owner only, not self) and `connect_member(gid, member_id)`
  (connect after joining). `revoke_invite` becomes owner only.
- App UI for join/connect/remove lands with P6-T07+ (after the P5 sync go/no-go). The server part
  ships now.
- Group lock (#89) is not needed: rotating the link plus removing people covers it.

## Revisit when

Groups need more than one admin, or link sharing is abused despite rotation (then add optional approval).
