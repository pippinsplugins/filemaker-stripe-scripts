# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FileMaker Pro scripts for Stripe payment integration using **Stripe Connect** with Standard accounts. Connected accounts are created via API and onboarded through Stripe's hosted flow. The platform processes charges on their behalf while collecting an application fee.

## Architecture

- **scripts/**: FileMaker script definitions (one file per Stripe operation)
  - Scripts 01-06: Customer and card management (create customer, add/update/delete/list cards, charge)
  - Scripts 07-11: Stripe Connect (create account, onboarding link, check status, disconnect)
  - Each script follows a consistent pattern: set variables → build cURL options → call Stripe API → parse JSON response → handle errors → store results

### Stripe Connect Model
- **Connect type**: Standard accounts created via API (no OAuth server needed)
- **Charge type**: Destination charges — platform creates the PaymentIntent with `transfer_data[destination]` and `application_fee_amount`
- **Flow**: Create Standard account via API → user completes Stripe-hosted onboarding → charges route funds to connected account minus platform fee
- Platform API key (`StripeConfig::ApiKey`) is used for all API calls
- Standard accounts have full access to dashboard.stripe.com (no login link scripts needed)

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
