---
title: "Carpool Cost Split for Longer Trips | mitlio"
description: "Split the cost of a shared long-distance drive including tolls: fuel, extras and the number of people, with a worked example. Free, no sign-up."
h1: "Carpool cost split: share the cost of a longer drive"
lead: "Fuel plus tolls, divided by everyone in the car. The calculator keeps the sums exact."
linkLabel: "Carpool cost split"
de: fahrgemeinschaft-kosten-aufteilen
example:
  input:
    distanceKm: 320
    consumptionPer100km: 7
    pricePerUnit: 1.8
    persons: 5
    driverPays: true
    tollsEur: 18
  compare:
    persons: 4
  text: |
    Five of you drive {km} km at {cons} l/100 km, fuel at €{price} per litre, plus {tolls} in tolls. The trip costs {total} in all, so each person pays {perPerson}.

    With four people the total stays at {total2} and each share rises to {perPerson2}.
howto:
  name: "How to split carpool costs"
  steps:
    - name: "Enter distance and fuel"
      text: "Add the distance, consumption and price per litre."
    - name: "Add tolls and extras"
      text: "Put tolls, ferries or parking into the extras field so they are split too."
    - name: "Set the people"
      text: "Enter everyone in the car and choose whether the driver pays a share."
faq:
  - q: "Are tolls part of the split?"
    a: "Yes, if you enter them under tolls and extras. They are added to the fuel cost before dividing."
  - q: "What if someone joins halfway?"
    a: "Run the calculator for each leg with the people actually in the car, and add the amounts per person."
  - q: "Do I need to include wear on the car?"
    a: "Only if you want to. Add an agreed amount under extras. Nothing is added automatically."
  - q: "How is the total rounded?"
    a: "To the cent. Leftover cents go to some people so the shares add up exactly."
related:
  - split-fuel-costs
  - commuter-carpool
  - fuel-cost-calculator
  - passenger-cost-calculator
---

## What belongs in the total

On a longer drive the fuel is the biggest cost, but tolls, ferries and parking can add up too. List them once, before the trip, so nobody is surprised.

`distance ÷ 100 × consumption × price + tolls and extras`

Divide that by the number of people and you have each person's share.

## Make it easy for everyone

- **Agree on the rules** before you set off: driver pays a share or not, tolls included or not.
- **Keep receipts** for tolls, so the extras are the real amounts.
- **Settle right away** with a link, so nobody has to chase money.
- **Currency:** the default is euros and kilometres, but the numbers work in any currency.
