# Decisions

Three questions the description doesn't answer, each chosen because the answer changes the model.

## 1. Does a drop-off ever cover more than one bike?

**Question:** When a customer brings in two bikes at once, is that one visit producing two
independent repair tickets, or one ticket with two bikes attached to it?

**Assumption:** One bike per repair ticket, always — matching "we write their name and phone on a
paper tag, tie it to the handlebars" (one tag, one bike, singular). Two bikes dropped off together
become two separate `repairs` rows, each with its own status and its own promised date.

**If the answer is the other way:** A repair would no longer belong to exactly one bike. I'd need a
`visits` table sitting above `repairs` (one visit, many repairs) so the two bikes could still be
tracked, priced, and marked ready independently, while still being picked up together.

## 2. Who is allowed to give a discount?

**Question:** The owner says "we charge less than the list says" — is that a decision only the
owner makes, or can any mechanic discount a job on their own judgment?

**Assumption:** Only the `owner` role can set `repair_line_items.price_charged` below the catalog
price. Mechanics can choose which jobs apply, but not override what they cost — the owner is the one
who described making that call personally.

**If the answer is the other way:** The schema doesn't have to change — `price_charged` is already
free-form per line item — but I'd add an `authorized_by_staff_id` column to `repair_line_items` so a
discount is traceable to whoever approved it, not just to the fact that one happened.

## 3. How does the shop know a bike changed hands?

**Question:** When a bike is sold, does the shop actively record the transfer, or does the "current
owner" just become whoever most recently dropped that serial number off?

**Assumption:** `bikes.owner_id` is overwritten whenever a different customer brings in a bike with a
serial number already on file. There's no explicit "sale" event — ownership drifts implicitly with
whoever's holding the bike at intake.

**If the answer is the other way:** A single `owner_id` column can't hold a history of who owned the
bike and when. I'd replace it with a `bike_ownerships` join table (`bike_id`, `customer_id`,
`started_at`, `ended_at`), so the shop could show not just who owns a bike now but who owned it during
a specific past repair.
