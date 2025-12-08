# Instantly → Google Sheets Sync (Webhook via Zapier)

**Time:** 10 minutes

1. In Instantly, open the campaign → **Settings** → **Webhooks** → add Zapier webhook URL.
2. In Zapier, create **Catch Hook** trigger; copy webhook URL into Instantly.
3. Send test event from Instantly; verify payload in Zapier (campaign, status, email, timestamp).
4. Add **Formatter** step to normalize timestamps to UTC and strip PII if needed.
5. Add **Google Sheets** action: Append Row to `Instantly Campaign Logs` sheet.
   - Columns: campaign_name, email, status, sent_at_utc, error_message.
6. Turn Zap on and send another test to confirm row insertion.
7. Share Sheets doc with Looker Studio connector account for reporting.
8. Document webhook owner and Zapier workspace in client folder.
