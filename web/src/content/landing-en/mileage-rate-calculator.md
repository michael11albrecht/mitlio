---
title: "Mileage Rate Calculator for Shared Rides | mitlio"
description: "Split ride costs with a flat rate per kilometre instead of fuel. Not a tax or reimbursement calculator; for friends, family and colleagues. Free."
h1: "Mileage rate calculator: share costs with a flat rate"
lead: "Instead of working out fuel, agree an amount per kilometre. Handy for rides among friends."
linkLabel: "Mileage rate calculator"
rate: true
de: kilometerpauschale-rechner
example:
  input:
    distanceKm: 120
    kmRate: 0.3
    persons: 3
    driverPays: true
  compare:
    roundTrip: true
  text: |
    At {km} km and a rate of €{rate} per km the trip costs {total}. For {n} people that is {perPerson} each.

    With a return trip ({kmTotal} km) the cost rises to {total2}, or {perPerson2} per person.
faq:
  - q: "What is a rate per kilometre?"
    a: "A fixed amount for each kilometre driven. It can cover fuel as well as wear and some fixed costs of the car."
  - q: "Which rate should I use?"
    a: "The calculator suggests €{rate} per km as an example only. You and your passengers decide what is fair; it is not an official rate."
  - q: "Is this a tax or expense calculator?"
    a: "No. It only splits the cost of a ride between people. It is not tax advice, and it does not calculate reimbursements for work trips."
  - q: "When is a rate better than fuel costs?"
    a: "For regular trips, or when you want wear to count. For one single trip, fuel costs are usually simpler."
related:
  - fuel-cost-calculator
  - split-fuel-costs
  - commuter-carpool
  - passenger-cost-calculator
---

## What this calculator is for

This is **not a tax or reimbursement calculator**. It helps you share a ride between friends, colleagues or family when you agree on a flat amount per kilometre instead of working out fuel.

That is useful because you do not need to know the car's consumption. A rate per kilometre can also cover some wear, while fuel depends on consumption and the day's price.

## How it works

`distance × rate per kilometre ÷ people`

The result is rounded to the cent, and leftover cents are shared out so the amounts add up exactly.

## Choosing a rate

- **Agree on it beforehand;** it applies because everyone accepts it.
- **Do not go below fuel cost.** A rate above it also covers some wear.
- **Do not mistake it for an official rate.** The example value is only a starting point.
- **Units:** kilometres and euros by default. The calculator takes any currency; miles are not supported yet.
