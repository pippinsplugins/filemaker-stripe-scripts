# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FileMaker Pro scripts for Stripe payment integration using **Stripe Connect** with Standard accounts. Connected accounts are created via API and onboarded through Stripe's hosted flow. The platform processes charges on their behalf while collecting an application fee.

## Architecture

- **scripts/**: FileMaker script definitions (one file per Stripe operation)
  - Scripts 01-06: Customer and card management (create customer, add/update/delete/list cards, charge)
  - Scripts 07-11: Stripe Connect (authorize account, complete connection, check status, disconnect)
  - Each script follows a consistent pattern: set variables → build cURL options → call Stripe API → parse JSON response → handle errors → store results

### Stripe Connect Model
- **Connect type**: Existing Standard accounts linked via OAuth (no server needed — desktop-friendly)
- **Charge type**: Direct charges — all API calls (customers, cards, charges) use the `Stripe-Account` header to operate directly on the connected account
- **Application fee**: `application_fee_amount` on PaymentIntents sends the platform fee back to your platform account
- **Flow**: User authorizes in browser → copies code from localhost redirect → script exchanges code for `acct_xxx` → customers and charges are created directly on the connected account
- Platform API key (`StripeConfig::ApiKey`) used for API calls; Connect Client ID (`StripeConfig::ConnectClientID`) used for OAuth
- Scripts 01-06 all include `Stripe-Account` header; scripts 07-11 (Connect management) do not
- Standard accounts manage their own dashboard at dashboard.stripe.com
- `http://localhost` is used as the OAuth redirect URI (must be added in Stripe Connect settings)

### Key Tables
- `StripeConfig`: Platform credentials and Connect settings (single-record)
- `Customers`: End customers who are charged
- `ConnectedAccounts`: Users who connect their Stripe accounts to the platform
- `PaymentMethods`: Stored card tokens (`pm_xxx`)
- `Payments`: Transaction records with fee breakdown

## Key Conventions

- Stripe API version: 2025-04-30 (set via `Stripe-Version` header in each script)
- All API calls use Bearer token auth with the platform key
- Error handling: every script checks for `JSONGetElement($response; "error.message")` after each API call
- Payment methods use the Stripe PaymentMethod API (pm_xxx tokens), not the legacy Token/Source API
- Card details are never stored in FileMaker — only Stripe token references
- Application fee is configurable via `StripeConfig::ApplicationFeePercent`

## FileMaker Dependencies

- FileMaker Pro 19+ (required for native JSON functions and enhanced cURL in Insert from URL)
- Key fields: `Customers::StripeCustomerID`, `ConnectedAccounts::StripeAccountID`, `PaymentMethods::StripePaymentMethodID`
