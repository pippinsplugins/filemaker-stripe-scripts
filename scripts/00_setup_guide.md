# FileMaker Setup Guide for Stripe Integration

## Required FileMaker Tables and Fields

### StripeConfig (single-record utility table)
| Field | Type | Purpose |
|-------|------|---------|
| ApiKey | Text | Your Stripe secret key (sk_test_... or sk_live_...) |

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

### Payments (new table for transaction records)
| Field | Type | Purpose |
|-------|------|---------|
| PaymentID | Number (auto-enter serial) | Primary key |
| CustomerID_FK | Number | Foreign key to Customers |
| StripePaymentIntentID | Text | `pi_xxx` |
| StripeChargeID | Text | `ch_xxx` |
| Amount | Number | Dollar amount |
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

## Stripe Test Card Numbers

| Number | Brand | Behavior |
|--------|-------|----------|
| 4242424242424242 | Visa | Succeeds |
| 4000002500003155 | Visa | Requires 3D Secure |
| 4000000000009995 | Visa | Declines (insufficient funds) |
| 5555555555554444 | Mastercard | Succeeds |
| 378282246310005 | Amex | Succeeds |

Use any future expiry date and any 3-digit CVC (4-digit for Amex).

## Script Execution Order for New Setup

1. Create the tables, fields, and layouts above
2. Add your Stripe API key to the StripeConfig table
3. Run **01_create_customer** on a customer record to register them in Stripe
4. Run **02_add_card** to attach a payment method
5. Run **03_charge_stored_card** to process a payment
6. Use **04_update_card**, **05_delete_card**, **06_list_cards** as needed
