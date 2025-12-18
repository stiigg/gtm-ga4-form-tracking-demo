# GA4 BigQuery Export Schema for This Repo

This repository’s BigQuery templates assume GA4 events are exported to BigQuery and that
form submissions are tracked as the GA4 event:

- `event_name = 'generate_lead'`

GA4 exports event-level data into daily tables like `events_YYYYMMDD`.
If streaming export is enabled, GA4 also creates `events_intraday_YYYYMMDD`. [Google Help][4]

---

## Expected custom parameters for form tracking

This implementation expects the following custom parameters to be present in the GA4 export
inside the `event_params` array (keys may be customized in your GTM setup).

| Parameter key | Type (typical) | Example | Purpose |
|---|---|---|---|
| `form_id` | string | `contact-form-footer` | Stable identifier per form instance |
| `form_type` | string | `lead` / `support` / `partner` | Business classification |
| `form_location` | string | `homepage-hero` / `pricing-cta` | Placement context |
| `form_topic` | string | `sales` / `support` / `partnership` | Intent signal |
| `form_plan` | string | `basic` / `pro` / `enterprise` | Tier selection (optional) |

If your implementation uses different parameter keys, update the SQL templates accordingly.

---

## SQL extraction pattern (GA4 nested schema)

GA4 stores parameters as an array of key/value objects (`event_params`), so extracting a parameter
typically looks like:

```sql
(SELECT value.string_value
 FROM UNNEST(event_params)
 WHERE key = 'form_id') AS form_id
```

(Use `int_value`, `float_value`, `double_value`, etc., depending on the parameter type.)

---

## Validation queries (run these first)

### 1) Confirm you have form events for a day

```sql
SELECT
  event_name,
  COUNT(*) AS events
FROM `project.dataset.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
  AND event_name = 'generate_lead'
GROUP BY event_name;
```

### 2) Check parameter coverage

```sql
SELECT
  COUNT(*) AS total_generate_lead,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key='form_id') IS NOT NULL) AS has_form_id,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key='form_type') IS NOT NULL) AS has_form_type,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key='form_location') IS NOT NULL) AS has_form_location
FROM `project.dataset.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
  AND event_name = 'generate_lead';
```

If `has_form_id` is far lower than `total_generate_lead`, your GTM/GA4 implementation likely
isn’t sending that parameter key (or it’s named differently).

---

## Official reference

GA4 BigQuery Export schema (Analytics Help): [Google Help][4]

[4]: https://support.google.com/analytics/answer/7029846?hl=en&utm_source=chatgpt.com "BigQuery Export schema - Analytics Help - Google Help"
