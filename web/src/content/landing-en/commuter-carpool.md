---
title: "Commuter Carpool Cost Calculator | mitlio"
description: "Share the cost of a regular commute: per-day cost for a round trip, split between everyone in the car. Worked example, free and no sign-up."
h1: "Commuter carpool: what does each trip cost?"
lead: "Work out one day's round trip, then agree on a fair way to share it with your carpool."
linkLabel: "Commuter carpool cost"
de: pendler-fahrgemeinschaft
example:
  input:
    distanceKm: 28
    consumptionPer100km: 5.8
    pricePerUnit: 1.8
    persons: 3
    driverPays: true
    roundTrip: true
  compare:
    persons: 2
  text: |
    Your commute is {km} km each way, {kmTotal} km there and back at {cons} l/100 km and €{price} per litre. One day costs {total}, so each of the {n} people pays {perPerson}.

    With two people in the car each pays {perPerson2} per day.
howto:
  name: "How to set up a commute split"
  steps:
    - name: "Calculate one day"
      text: "Enter the one-way distance and switch on round trip."
    - name: "Fix a rhythm"
      text: "Decide whether you settle per day, per week or per month."
    - name: "Rotate or pay"
      text: "Either take turns driving, or have passengers pay the driver each time."
faq:
  - q: "Should we take turns or pay the driver?"
    a: "Taking turns is simplest if the cars and routes are similar. Paying the driver works when one person always drives."
  - q: "How do I handle days someone is absent?"
    a: "Calculate that day with fewer people. The cost per person goes up a little."
  - q: "How often should we settle up?"
    a: "Weekly or monthly keeps it simple. Add up the daily amounts once instead of passing small change around."
  - q: "Is this tax advice?"
    a: "No. This calculator only splits costs between people. Commuting and tax rules differ by country; ask a tax advisor."
related:
  - carpool-cost-split
  - split-fuel-costs
  - mileage-rate-calculator
  - fuel-cost-calculator
---

## A commute is a repeat trip

Because you drive the same route again and again, you only need to calculate once. Take the one-way distance, switch on round trip, and you have the cost of one day.

`distance × 2 ÷ 100 × consumption × price per litre`

## Keeping a regular split fair

- **Write the rule down** in the group chat so nobody has to remember it.
- **Pick one price** for fuel and update it only now and then, for example monthly.
- **Do not forget the driver.** If the car would have driven anyway, an equal share still keeps it fair.
- **Units:** distances are in kilometres and amounts in euros by default; any currency works if you read the numbers that way.
