<!-- Changed for Owner 1.0 (2026-11-27): Owner ships no connectors of its own, so this says the owner connects them in their AI app; its scope line calls this Owner's rule, where it called it its maker's positioning for the plugin. -->
# Connector neutrality — plugin-wide rule

Scope: **every skill, command, reference file, and onboarding flow.** This is
Owner's rule, not a house preference: the owner's
tool set decides what gets called. The plugin never decides which vendor an
owner should have.

---

## The rule

**Connectors in the same category are peers.** A ledger is a ledger. A CRM is
a CRM. A mailbox is a mailbox. No skill names one of them as the default, the
primary, the one that takes precedence, the fallback vendor, the alternate,
or the lesser path. Name what is connected, and run on that.

Categories this applies to, and the connectors in each today (alphabetical,
which is the order every list in the plugin uses when more than one is named):

| Category | Connectors |
|---|---|
| Accounting ledger | MYOB, NetSuite, QuickBooks, Xero, Zoho Books |
| CRM | HubSpot, Monday.com, Salesforce, Zoho CRM |
| Lead data and enrichment | Apollo, Clay |
| Mail | Gmail, Microsoft 365 |
| Calendar | Google Calendar |
| Payroll | Gusto, QuickBooks Payroll |
| Payments | PayPal, Square, Stripe |
| Storefront and point of sale (holds orders and stock) | Shopify, Square |
| Files | Google Drive, Microsoft 365 |
| Support | Zoho Desk |

Salesforce is reached as a custom connector the owner adds (its Headless 360 server has a per-org address and OAuth client), not through the plugin manifest; once added it is a peer like the rest. A connector that is not on this table is reached through `build-connector`,
which checks the connector directory first and connects through Zapier
otherwise. Once connected, it joins its category as a peer.

---

## What "peers" means in practice

**Gating is by category, never by vendor.** A skill that needs a ledger says
"a ledger (MYOB, NetSuite, QuickBooks, Xero, or Zoho Books)," and any one of
them opens the gate. The router's connector map is written the same way.

**Two connected in one category: read both, total from one.** Each connector
supplies what it uniquely holds. Any figure that must come from a single
place — a cash balance, a revenue total, an AR figure — comes from the one
the owner names as the source of record for that run, and the output says
which. Never sum the same figure across two connectors: that double-counts.
The router's Step 5 multiple-choice is how the owner names it; the answer
sticks for the session and can be stored in the business context.

**Capability limits are stated as capabilities, not as judgments.** "This
connector has no bill-write path, so the entries are exported for keying in"
is a capability. "Xero is read-only here, better if QuickBooks is
mid-migration" is a ranking. Write the first kind. Where a connector genuinely
cannot do part of a skill (MYOB holds no cash balance; a read-only ledger
cannot post a journal; Zoho Books holds no bill object, no bank feed, and no
report endpoints), say what it cannot do and what the skill does instead, in
one line, without comparing it to another vendor.

**Metered connectors say the price before spending.** A lead-data connector
charges credits per enriched row. A skill that uses one names the row count
and asks once per run before enriching. That is an approval gate, not a
ranking.

**Vendor-specific technical notes are fine.** A file like
`shared/quickbooks-report-traps.md` documents real behaviour of one
connector. That is not a preference; it is a gotcha. Keep those, label them
as connector-specific, and add sibling files for other connectors as their
traps are found.

**Worked examples may name a vendor.** An example has to run on something.
Naming QuickBooks in a transcript is fine; saying "let's connect QuickBooks
first" as advice is not. Examples show the owner's tool being used, never
being chosen for them.

---

## One connector, one registration

Owner declares no connectors of its own (no `.mcp.json`): the owner connects their tools in their AI app, so each
product has one entry, the owner's own. The plugin-scoped copies the original described (`small-business:<name>`,
tools named `mcp__plugin_small-business_<server>__<tool>`) do not exist here; where another page mentions one, it does
not apply. Rules:

1. **Call the owner's own entry.** It already has their consent.
2. **A product that is not connected** is the ordinary "connect it" path: say once that the owner can add it in their
   AI app's connectors, and carry on from a file or a paste.
3. **Owner-facing text names the product.** "Trello," never a registration name. The business-context
   `Connected tools` line stores product names only.

---

## Onboarding and the router

- **Ask, never recommend.** Onboarding asks what the owner uses for
  bookkeeping, for customers, for mail. It does not propose a vendor. If the
  owner has no tool in a category, the recipe's zero-connector path runs and
  the category is named ("when you pick a bookkeeping tool, connect it and
  this gets deeper"), without a product name attached.
- **We have it, or we connect it, or we fall back.** In that order, said once,
  with the trade-off in one line. Never pitch a competing tool because ours
  is missing.
- **The router prefers what is connected.** Its Step 5 rules already say so.
  The neutrality rule adds: when nothing in a category is connected, the
  router names the category and the fallback, not a vendor to go and buy.

---

## What this rule does not change

- **Approval gates.** Neutral does not mean permissive. Every write still
  needs its yes.
- **Honesty about scope.** A skill built for one country's tax regime says
  so (`shared/currency-and-locale.md`). That is a scope statement, not a
  vendor ranking.

---

## Words to avoid between same-category connectors

default · primary · takes precedence · fallback (as a vendor label) · alternate
· alternative · lesser · backup path · the one most owners use · preferred

Use instead: "whichever is connected," "the connected ledger," "a ledger
(MYOB, NetSuite, QuickBooks, Xero, or Zoho Books)," "the one the owner named
as source of record."
