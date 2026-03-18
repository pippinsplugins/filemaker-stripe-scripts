# FileMaker Setup Guide for Stripe Integration

## Required FileMaker Tables and Fields

### StripeConfig (single-record utility table)
| Field | Type | Purpose |
|-------|------|---------|
| ApiKey | Text | Your platform's Stripe secret key (sk_test_... or sk_live_...) |
| ConnectReturnURL | Text | Any URL to show after onboarding completes (e.g., a simple "You can close this tab" page) |
| ConnectRefreshURL | Text | Any URL to show if onboarding link expires (e.g., same as return URL) |
| ApplicationFeePercent | Number | Application fee percentage your platform keeps (e.g., 10 for 10%) |

### Customers (your existing customer table — add these fields)
| Field | Type | Purpose |
|-------|------|---------|
| CustomerID | Number (auto-enter serial) | Primary key |
| FirstName | Text | |
| LastName | Text | |
| Email | Text | |
| Phone | Text | |
| Notes | Text | |
| Address1 | Text | |
| Address2 | Text | |
| City | Text | |
| State | Text | |
| PostalCode | Text | |
| Country | Text | 2-letter ISO code (US, CA, GB) |
| StripeCustomerID | Text | Stores `cus_xxx` from Stripe |
| DefaultPaymentMethod | Text | Stores `pm_xxx` of default card |
| TempCardNumber | Text | **Testing only** — card number input |
| TempExpMonth | Text | **Testing only** — expiration month |
| TempExpYear | Text | **Testing only** — expiration year |
| TempCVC | Text | **Testing only** — CVC input |

> **PCI Note:** The `Temp*` fields are for testing with Stripe test cards only. In production, card numbers must be collected via Stripe.js/Elements in a web viewer — never stored in FileMaker.

### PaymentMethods (new table for stored cards)
| Field | Type | Purpose |
|-------|------|---------|
| PaymentMethodID | Number (auto-enter serial) | Primary key |
| CustomerID_FK | Number | Foreign key to Customers |
| StripeCustomerID | Text | `cus_xxx` |
| StripePaymentMethodID | Text | `pm_xxx` |
| CardLast4 | Text | Last 4 digits for display |
| CardBrand | Text | visa, mastercard, amex, etc. |
| CardExpMonth | Text | |
| CardExpYear | Text | |
| BillingName | Text | Name on card |
| IsDefault | Number | 1 = default payment method |

### ConnectedAccounts (new table for Stripe Connect Standard accounts)
| Field | Type | Purpose |
|-------|------|---------|
| ConnectedAccountID | Number (auto-enter serial) | Primary key |
| UserID_FK | Number | Foreign key to your Users/Members table |
| StripeAccountID | Text | `acct_xxx` — the connected account ID |
| Email | Text | Account email |
| Country | Text | 2-letter ISO code (US, GB, etc.) |
| BusinessType | Text | `individual`, `company`, or `non_profit` |
| BusinessName | Text | Business name from Stripe |
| ChargesEnabled | Text | Whether account can accept charges |
| PayoutsEnabled | Text | Whether account can receive payouts |
| DetailsSubmitted | Text | Whether onboarding details have been submitted |
| OnboardingComplete | Number | 1 = fully onboarded |
| IsConnected | Number | 1 = active connection |
| DisabledReason | Text | Reason if account is disabled |
| CreatedDate | Timestamp | When account was created |
| DisconnectedDate | Timestamp | When account was disconnected |
| LastChecked | Timestamp | Last time status was refreshed |

### Payments (new table for transaction records)
| Field | Type | Purpose |
|-------|------|---------|
| PaymentID | Number (auto-enter serial) | Primary key |
| CustomerID_FK | Number | Foreign key to Customers |
| ConnectedAccountID | Text | `acct_xxx` — which connected account received funds |
| StripePaymentIntentID | Text | `pi_xxx` |
| StripeChargeID | Text | `ch_xxx` |
| Amount | Number | Total dollar amount charged |
| ApplicationFee | Number | Platform fee kept (dollars) |
| NetToConnectedAccount | Number | Amount transferred to connected account (dollars) |
| Currency | Text | `usd`, `eur`, etc. |
| Status | Text | `succeeded`, `failed`, etc. |
| Description | Text | |
| PaymentDate | Timestamp | |

### Invoices (optional — if charging from invoice records)
| Field | Type | Purpose |
|-------|------|---------|
| InvoiceNumber | Text | |
| AmountDue | Number | Dollar amount (script converts to cents) |

## Required Layouts

Create these layouts (can be minimal — they're used for scripted record creation):
- **PaymentMethods** — based on the PaymentMethods table
- **Payments** — based on the Payments table
- **ConnectedAccounts** — based on the ConnectedAccounts table

## Stripe Test Card Numbers

| Number | Brand | Behavior |
|--------|-------|----------|
| 4242424242424242 | Visa | Succeeds |
| 4000002500003155 | Visa | Requires 3D Secure |
| 4000000000009995 | Visa | Declines (insufficient funds) |
| 5555555555554444 | Mastercard | Succeeds |
| 378282246310005 | Amex | Succeeds |

Use any future expiry date and any 3-digit CVC (4-digit for Amex).

## Stripe Connect Setup (Required)

This application uses **Stripe Connect** with Standard accounts. No OAuth server required — accounts are created via API and users complete onboarding on Stripe's hosted page. Standard accounts have full access to the Stripe Dashboard at dashboard.stripe.com.

1. In your Stripe Dashboard, go to **Settings → Connect**
2. Set up your **Platform profile** (required before going live)
3. Set `StripeConfig::ApplicationFeePercent` to your desired fee (e.g., 10 for 10%)
4. Optionally set `ConnectReturnURL` and `ConnectRefreshURL` to any web page (e.g., a simple page that says "Onboarding complete — you can close this tab and return to FileMaker")

## Script Execution Order for New Setup

### Initial platform setup:
1. Create the tables, fields, and layouts above
2. Add your Stripe API key to the StripeConfig table

### For each user connecting their Stripe account:
3. Run **07_create_connect_account** — creates Standard account and opens onboarding in browser
4. If the onboarding link expires, run **08_create_onboarding_link** to generate a new one
5. Run **09_check_account_status** to verify onboarding is complete

### For each customer/payment:
6. Run **01_create_customer** on a customer record to register them in Stripe
7. Run **02_add_card** to attach a payment method
8. Run **03_charge_stored_card** to process a payment (with application fee → connected account)
9. Use **04_update_card**, **05_delete_card**, **06_list_cards** as needed

### Account management:
- **11_disconnect_account** — remove a connected Standard account from the platform
- Standard account users manage their own settings, payouts, and disputes at dashboard.stripe.com
