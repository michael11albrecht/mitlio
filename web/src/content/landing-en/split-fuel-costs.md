---
title: "Split Fuel Costs Fairly: Who Pays What? | mitlio"
description: "Split fuel costs for a shared car ride: work it out from distance and consumption, or from a receipt. Worked example, free, no sign-up."
h1: "Split fuel costs: how to keep it fair"
lead: "You filled the tank, the others came along. See in seconds what everyone owes."
linkLabel: "Split fuel costs"
de: spritkosten-teilen
example:
  input:
    distanceKm: 400
    consumptionPer100km: 6.8
    pricePerUnit: 1.79
    persons: 4
    driverPays: true
  compare:
    persons: 5
  text: |
    You drive {km} km, the car uses {cons} l/100 km and a litre costs €{price}. The fuel comes to {total}. With {n} people that is {perPerson} each.

    If one more person joins, each share drops to {perPerson2}. The total stays at {total2}; only the split changes.
howto:
  name: "How to split fuel costs in three steps"
  steps:
    - name: "Find the total"
      text: "Use the fuel receipt, or let the calculator work it out from distance, consumption and price."
    - name: "Count the people"
      text: "Decide whether the driver pays a share and enter how many people are in the car."
    - name: "Ask for the amount"
      text: "Send the amount by link or message so everyone can pay straight away."
faq:
  - q: "Split by receipt or by distance?"
    a: "A receipt is exact if the tank was filled for this very trip. Usually it was filled before or after, so distance and consumption is fairer."
  - q: "Should the driver pay too?"
    a: "It is common, because it keeps the split even: everyone pays the same share. Agree on it beforehand."
  - q: "What if only part of the route is shared?"
    a: "Calculate with the distance you actually shared. For a detour taken for one person, an extra amount is fair."
  - q: "How are amounts rounded?"
    a: "To the cent, with leftover cents distributed so the shares add up exactly to the total."
related:
  - fuel-cost-calculator
  - carpool-cost-split
  - passenger-cost-calculator
  - ev-charging-cost-split
---

## Two ways to get the amount

**By receipt:** take the last fuel bill and divide it. This works if the tank was filled for exactly this trip.

**By distance:** use `distance ÷ 100 × consumption × price per litre`. This is usually more accurate because it only counts the shared trip, not the fill-up before or after.

## What to watch for

- **Equal shares:** everyone pays the same, wherever they sit.
- **Real price:** use what you actually paid, not an average.
- **Tolls:** add them under tolls and extras; they are split too.
- **Settle quickly:** name the amount right after the trip. It gets awkward later.

Currency does not matter to the maths: use your own currency's numbers. The default unit is the kilometre.
