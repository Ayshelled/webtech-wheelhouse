# Domain Model

## Diagram

![Wheelhouse domain model](domain-model.png)

## Lifecycle

States a repair moves through:

`Tagged → Diagnosing → Awaiting Approval → Approved → In Progress → Ready for Pickup → Picked Up`

with a side branch:

`Awaiting Approval → Declined → Ready for Pickup → Picked Up`

and a shortcut for same-day jobs the owner mentioned (a flat tyre needs no quote or approval):

`Tagged → In Progress`

### Allowed transitions

| From | To |
|---|---|
| Tagged | Diagnosing |
| Tagged | In Progress *(same-day job, no diagnosis needed)* |
| Diagnosing | Awaiting Approval |
| Awaiting Approval | Approved |
| Awaiting Approval | Declined |
| Approved | In Progress |
| In Progress | Ready for Pickup |
| Declined | Ready for Pickup *(bike returned the way it arrived)* |
| Ready for Pickup | Picked Up |

### Explicitly not allowed

| From | To | Why not |
|---|---|---|
| Awaiting Approval | In Progress | Skips the customer's yes. The owner is explicit: "wait for them to say yes before we touch it." |
| Declined | Approved | Once declined, the customer already collected the bike as-is. A change of mind is a new drop-off, not a resurrection of the old ticket. |
| Ready for Pickup | In Progress | A repair marked ready doesn't quietly reopen. If more work is found, it becomes a new repair record — the old one stays an honest, permanent statement of what was true at that pickup. |
| Picked Up | *(anything)* | A closed repair is final, for the same reason last year's invoice can't change: it's a historical record, not a working document. |

## Entities and the story that requires each one

| Entity | Required by |
|---|---|
| `customers` | Story 1 |
| `bikes` | Stories 3, 16 |
| `staff` | Stories 2, 5, 8 |
| `repairs` | Stories 1, 10, 11 |
| `repair_photos` | Story 4 |
| `diagnosis_notes` | Story 5 |
| `service_catalog_items` | Stories 13, 14 |
| `repair_line_items` | Stories 6, 12 |

## Two decisions defended

### The thing and the copy of the thing

Two blue Trek Marlins in the shop at the same week are two rows in `bikes`, distinguished by a
`unique` `serial_number` — not two counts against one "Trek Marlin" row. A single table with a
`make`, `model`, and a `quantity` column would answer "how many blue Marlins came in this month,"
but it can't answer "which one is this customer's," because a quantity column has no way to attach a
specific repair history, a specific set of intake photos, or a specific current owner to *one*
physical bike out of the two. `serial_number` is what the owner actually identifies a bike by, once
March happened — so the model does too.

### Derived, or stored?

**Not stored:** whether a repair is overdue. It's never a column — it's `promised_date < today AND
status NOT IN ('Ready for Pickup', 'Picked Up')`, computed when the owner's overdue screen is asked
for it. Storing an `is_overdue` flag would require someone (or a background job) to keep it in sync
with the passage of time itself, and it would go stale the moment "today" changes without anyone
touching the row.

**Stored despite being derivable:** `repair_line_items.price_charged`. In principle it's just
`service_catalog_items.price` looked up on the day of the repair. But the owner is explicit that the
list goes up every January and "last year's invoices cannot change" — if `price_charged` weren't
stored and we joined to the catalog for the number instead, raising a job's price in January would
silently rewrite the total on every invoice from the year before. Storing the price at the moment
it's charged is what keeps a closed repair a fixed historical fact.
