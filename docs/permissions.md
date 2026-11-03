# Workshop permissions

The tables below describe the Pundit policies. "No" means the action is refused with HTTP 403 for a
signed-in account. Visitors are redirected to sign in for protected pages; service catalog reads
remain public.

## Customers

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| Index | Yes | Yes | No |
| Show | Yes | Yes | No |
| New | Yes | Yes | No |
| Create | Yes | Yes | No |
| Edit | Yes | Yes | No |
| Update | Yes | Yes | No |
| Destroy | Yes | No | No |

## Bikes

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| Index | Yes | Yes | No |
| Show | Yes | Yes | No |
| New | Yes | Yes | No |
| Create | Yes | Yes | No |
| Edit | Yes | Yes | No |
| Update | Yes | Yes | No |
| Destroy | Yes | No | No |

## Repairs

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| Index | Yes; all repairs | Yes; all repairs | Yes; only repairs assigned to their linked staff member |
| Show | Yes; every repair | Yes; every repair | Only repairs assigned to their linked staff member |
| New | Yes | Yes | No |
| Create | Yes | Yes | No |
| Edit | Yes; every repair, including handed-back repairs | Only repairs not handed back | Only their assigned repairs that have not been handed back |
| Update | Yes; every repair, including handed-back repairs | Only repairs not handed back | Only their assigned repairs that have not been handed back |
| Destroy | Yes | No | No |
| Remove photo | Yes | Only repairs not handed back | No |

Repair scopes return all repairs to the owner and counter, and only repairs assigned to the account's
linked staff member to a mechanic. A mechanic without a linked staff member sees no repairs. A repair
is handed back when `handed_back_at` is set; in the lifecycle this is the final `Picked Up` state.
Mechanics may update only status, diagnosis, and intake photos on their own open repairs. The owner
and counter may update every repair form field, subject to the update permissions above. The
intake-user account is always taken from the signed-in session.

## Services

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| Index | Yes; public | Yes; public | Yes; public |
| Show | Yes; public | Yes; public | Yes; public |
| New | Yes | No | No |
| Create | Yes | No | No |
| Edit | Yes | No | No |
| Update | Yes | No | No |
| Destroy | Yes | No | No |

## Staff

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| Index | Yes | Yes | Yes |
| Show | Yes | Yes | Yes |
| New | Yes | No | No |
| Create | Yes | No | No |
| Edit | Yes | No | No |
| Update | Yes | No | No |
| Destroy | Yes | No | No |
