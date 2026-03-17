# FileMaker Setup Guide for Stripe Integration

## Required FileMaker Tables and Fields

### StripeConfig (single-record utility table)
| Field | Type | Purpose |
|-------|------|---------|
| ApiKey | Text | Your platform's Stripe secret key (sk_test_... or sk_live_...) |
| ConnectClientID | Text | Your platform's Connect client ID (ca_xxx) — found in Stripe Dashboard → Settings → Connect |
| ConnectRedirectURI | Text | OAuth redirect URI (must match what's set in Stripe Connect settings) |
| ConnectReturnURL | Text | URL shown after Express onboarding completes |
| ConnectRefreshURL | Text | URL shown if Express onboarding link expires |
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

### ConnectedAccounts (new table for Stripe Connect OAuth)
| Field | Type | Purpose |
|-------|------|---------|
| ConnectedAccountID | Number (auto-enter serial) | Primary key |
| UserID_FK | Number | Foreign key to your Users/Members table |
| StripeAccountID | Text | `acct_xxx` — the connected account ID |
| AccessToken | Text | OAuth access token (store securely) |
| RefreshToken | Text | OAuth refresh token (store securely) |
| BusinessName | Text | Business name from Stripe |
| Email | Text | Account email |
| ChargesEnabled | Text | Whether account can accept charges |
| PayoutsEnabled | Text | Whether account can receive payouts |
| IsConnected | Number | 1 = active connection |
| Livemode | Text | true/false |
| OAuthState | Text | Temporary CSRF state token |
| TempAuthCode | Text | Temporary field for manual code entry |
| OAuthStarted | Timestamp | When OAuth flow was initiated |
| ConnectedDate | Timestamp | When account was connected |
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

This application uses **Stripe Connect** with OAuth so users connect their existing Stripe accounts.

1. In your Stripe Dashboard, go to **Settings → Connect**
2. Set up your **Platform profile** (required before going live)
3. Copy the **Client ID** (ca_xxx) into `StripeConfig::ConnectClientID`
4. Add your **Redirect URI** to the Connect settings and to `StripeConfig::ConnectRedirectURI`
5. Set `StripeConfig::ApplicationFeePercent` to your desired fee (e.g., 10 for 10%)

## Script Execution Order for New Setup

### Initial platform setup:
1. Create the tables, fields, and layouts above
2. Add your Stripe API key and Connect Client ID to the StripeConfig table

### For each user connecting their Stripe account:
3. Run **07_create_connect_account** (starts OAuth — user authorizes in browser)
4. Run **08_complete_connect_oauth** (exchange auth code for account ID)
5. Run **09_check_account_status** to verify they can accept charges

### For each customer/payment:
6. Run **01_create_customer** on a customer record to register them in Stripe
7. Run **02_add_card** to attach a payment method
8. Run **03_charge_stored_card** to process a payment (with application fee → connected account)
9. Use **04_update_card**, **05_delete_card**, **06_list_cards** as needed

### Account management:
- **10_create_connect_login_link** — give connected users access to their Express Dashboard
- **11_disconnect_account** — revoke a connected account's access
