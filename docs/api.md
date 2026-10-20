# Wheelhouse API v1

All API responses use JSON, regardless of the request's `Accept` header. Errors use one
shape: `{"errors":["message"]}`. Dates are ISO 8601 calendar dates.

## Routes

| Verb | Path | Bearer token | Statuses |
| --- | --- | --- | --- |
| GET | `/api/v1/services` | No | 200 |
| GET | `/api/v1/services/:id` | No | 200, 404 |
| POST | `/api/v1/services` | Yes | 201, 400, 401, 422 |
| GET | `/api/v1/repairs` | Yes | 200, 400, 401 |
| GET | `/api/v1/repairs/:id` | Yes | 200, 401, 404 |

Requests that require authentication send `Authorization: Bearer YOUR_TOKEN`. The token is
stored in encrypted Rails credentials at `api.token`. Service creation accepts a JSON body
under the `service_catalog_item` key:

```json
{
  "service_catalog_item": {
    "name": "Brake adjustment",
    "price": "25.00"
  }
}
```

## Documents

Prices are decimal strings with two fractional digits, for example `"85.00"`. Keeping money
as a decimal string avoids floating-point rounding in clients; clients can parse it for
display without losing the value sent by the API.

A service document is the same for the collection, single-record, and creation responses:

```json
{
  "id": 7,
  "name": "Tune-up",
  "price": "85.00",
  "times_charged": 12
}
```

A repair document contains descriptive data rather than database foreign keys. Its state is
the enum key, and the customer decision is `true`, `false`, or `null` when not yet recorded:

```json
{
  "id": 12,
  "state": "ready_for_pickup",
  "checked_in_on": "2026-10-19",
  "promised_on": "2026-10-22",
  "handed_back_on": null,
  "bike": {
    "brand": "Surly",
    "model": "Straggler",
    "serial_number": "WHEEL-001"
  },
  "customer": {
    "name": "Ari Customer"
  },
  "lines": [
    {
      "service": "Tune-up",
      "price": "80.00"
    }
  ],
  "total": "80.00",
  "overdue": false,
  "customer_approved": true
}
```

The collection of repairs is a JSON array of repair documents:

```json
[
  {
    "id": 12,
    "state": "ready_for_pickup",
    "checked_in_on": "2026-10-19",
    "promised_on": "2026-10-22",
    "handed_back_on": null,
    "bike": {
      "brand": "Surly",
      "model": "Straggler",
      "serial_number": "WHEEL-001"
    },
    "customer": {
      "name": "Ari Customer"
    },
    "lines": [
      {
        "service": "Tune-up",
        "price": "80.00"
      }
    ],
    "total": "80.00",
    "overdue": false,
    "customer_approved": true
  }
]
```

Filter repairs by an enum key such as `GET /api/v1/repairs?state=ready_for_pickup`.
An unknown state returns `400` and lists the available enum keys.

All errors have one shape, including authentication failures, invalid input, and missing
records:

```json
{
  "errors": [
    "Record not found."
  ]
}
```

The repair document intentionally omits the customer's phone number, staff IDs and identities,
the bike/customer foreign keys, diagnosis, quote timestamps, and intake photos. The accounting
program needs the customer name, bike description, service names, charged prices, total,
lifecycle state, and dates, but not contact details or workshop-internal information.
