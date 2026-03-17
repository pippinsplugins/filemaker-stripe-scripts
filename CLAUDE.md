# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FileMaker Pro scripts for Stripe payment integration. Each script file contains step-by-step FileMaker script instructions that use the "Insert from URL" script step to interact with the Stripe REST API.

## Architecture

- **scripts/**: FileMaker script definitions (one file per Stripe operation)
  - Each script follows a consistent pattern: set variables → build cURL options → call Stripe API → parse JSON response → handle errors → store results
- **All scripts assume** a FileMaker table called `StripeConfig` with a field `ApiKey` holding the Stripe secret key (sk_...)
- **All scripts assume** a `Customers` table with fields for storing Stripe customer IDs, payment method tokens, and related data
- Scripts use FileMaker's native `JSONGetElement` function for parsing Stripe API responses
- cURL options are built using FileMaker's `"-X POST"` / `"-H header"` syntax for the `Insert from URL` step

## Key Conventions

- Stripe API version: 2023-10-16 (set via `Stripe-Version` header in each script)
- All API calls use Bearer token auth: `-H "Authorization: Bearer " & $apiKey`
- Error handling: every script checks for `JSONGetElement($response; "error.message")` after each API call
- Payment methods use the Stripe PaymentMethod API (pm_xxx tokens), not the legacy Token/Source API
- Card details are never stored in FileMaker — only Stripe token references (pm_xxx, cus_xxx)

## FileMaker Dependencies

- FileMaker Pro 19+ (required for native JSON functions and enhanced cURL in Insert from URL)
- Fields referenced across scripts: `Customers::StripeCustomerID`, `Customers::DefaultPaymentMethod`, `PaymentMethods::StripePaymentMethodID`
