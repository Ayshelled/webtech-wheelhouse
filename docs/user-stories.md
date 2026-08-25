# User Stories

Roles found in the owner's description: **Customer**, **Counter staff**, **Mechanic**, **Owner**.
Counter staff and Mechanic do the day-to-day work of the shop.

## Intake

1. As a **customer**, I want to drop off my bike with my name and phone recorded, so that the shop
   can identify my bike and reach me about it.
2. As a **counter staff member**, I want to tag a bike with the customer's name and phone number
   when it arrives, so that the bike can be matched back to its owner without asking around.
3. As a **counter staff member**, I want to record the bike's make, model and serial number at
   intake, so that two similar bikes in the shop at once are never confused with each other.
4. As a **counter staff member**, I want to photograph the bike when it arrives, so that nobody can
   dispute later who caused a scratch.

## Diagnosis and quoting

> **This story is too big, and I split it:**
> ~~As a mechanic, I want to manage a bike's repair from diagnosis through to pickup, so that the
> bike gets fixed correctly.~~ This bundles three separate pieces of value behind one story — a
> mechanic doing only the first piece today already has something usable tomorrow.

5. As a **mechanic**, I want to write my diagnosis as a paragraph or list, so that anyone in the
   shop can understand what's wrong with the bike without finding me in person.
6. As a **mechanic**, I want to select the jobs a bike needs from the price list and see the total,
   so that I can hand the owner a quote to give the customer.
7. As a **mechanic**, I want to mark a repair as ready for pickup once the approved jobs are done,
   so that the counter and the owner know without asking me directly.

## Approval

8. As an **owner**, I want to call the customer with the quote and record whether they said yes,
   so that no work starts on a bike without the customer's consent.
9. As a **customer**, I want to decline the proposed repair and collect my bike unrepaired, so that
   I don't pay for work I never agreed to.

## Status and tracking

10. As a **counter staff member**, I want to look up a bike and see whether it's ready, so that I
    can answer a phone call immediately instead of walking to the back to ask.
11. As an **owner**, I want to see which repairs are past their promised pickup day, so that I can
    act before the customer calls to complain.

## Pricing

12. As an **owner**, I want to give a specific repair a lower price than the list says, so that I
    can offer a regular customer a discount without changing the wall price for everyone.
13. As an **owner**, I want to update the price list every January, so that new prices apply going
    forward without changing what past customers were already charged.
14. As a **customer**, I want to see the shop's price list on the public website, so that I know
    what a tune-up costs without phoning to ask.

## History

15. As a **returning customer**, I want to see what was done to my bike last time, so that I don't
    have to remember or re-explain a repair I already paid for.
16. As the **new owner of a used bike**, I want to see that bike's repair history, so that I know
    about work like a replaced fork even though I wasn't the one who paid for it.

---

## Acceptance criteria

Four stories carry acceptance criteria below. Story 10 covers the empty-state case.

### Story 6 — Select jobs and see a total (Mechanic)

- Given a repair with no jobs selected yet, when I open the quote screen, then I see the full price
  list with each job's current price.
- Given I select two or more jobs, when the selection changes, then the total updates immediately
  without a page reload.
- Given I have selected at least one job, when I look at the screen, then I can see which specific
  jobs make up the total, not only the total itself.

### Story 8 — Record the customer's decision (Owner)

- Given a repair with a quote ready, when I record the customer's answer, then the repair moves to
  either "Approved" or "Declined" and no third state is possible.
- Given a repair is "Awaiting Approval", when a mechanic tries to start work on it, then the system
  does not allow it until a decision is recorded.
- Given I record "Approved", when I check the repair afterward, then the approval is timestamped, so
  we can show when consent was given if it's ever questioned.

### Story 10 — Is this bike ready? (Counter staff)

- Given a bike with a repair marked "Ready for Pickup", when I look it up, then the screen clearly
  shows "Ready" along with the pickup-ready date.
- Given a bike with a repair still "In Progress", when I look it up, then the screen shows the
  current status and the promised date, not just "not ready."
- Given a search that matches no bike or customer, when I look it up, then the screen says plainly
  that nothing was found, instead of showing an empty list with no explanation.

### Story 13 — Update the price list each January (Owner)

- Given I raise a job's price, when I save the change, then repairs already invoiced before the
  change keep their original charged price.
- Given a new price takes effect, when a mechanic opens the quote screen for a new repair, then they
  see only the new price, not the old one.
- Given I raise a price, when I look at last year's invoices, then the total on each one is
  unchanged from what the customer was actually charged.
