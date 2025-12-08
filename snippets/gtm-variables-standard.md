# Standard GTM Variables

Create these 12 Data Layer Variables in every new container. All use Data Layer Version 2.

| Variable Name | Data Layer Key | Notes |
|---------------|----------------|-------|
| DLV - form_id | form_id | Used in generate_lead event
| DLV - form_type | form_type | lead/support/sales
| DLV - form_location | form_location | page or section
| DLV - form_fields | form_fields | object of submitted fields
| DLV - ecommerce.items | ecommerce.items | reusable across events
| DLV - ecommerce.value | ecommerce.value | monetary value
| DLV - ecommerce.currency | ecommerce.currency | currency code
| DLV - ecommerce.transaction_id | ecommerce.transaction_id | purchase deduping
| DLV - page_category | page_category | optional metadata
| DLV - user_role | user_role | if provided by app
| DLV - client_id | client_id | from GA4 config if exposed
| DLV - debug_mode | debug_mode | flag for QA

Set **Data Layer Version** to `Version 2` and leave **Default Value** blank unless instructed.
