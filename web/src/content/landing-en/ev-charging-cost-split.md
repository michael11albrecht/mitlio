---
title: "EV Charging Cost Split Calculator | mitlio"
description: "Split the electricity cost of a trip in an electric car: kWh per 100 km and price per kWh in, each person's share out. Free, no sign-up."
h1: "Electric car: split charging costs fairly"
lead: "Electricity instead of fuel: enter consumption in kWh and your price, and see what each person pays."
linkLabel: "EV charging cost split"
de: elektroauto-ladekosten-teilen
example:
  input:
    distanceKm: 200
    consumptionPer100km: 19
    pricePerUnit: 0.45
    persons: 3
    driverPays: true
    ev: true
  compare:
    roundTrip: true
  text: |
    You drive {km} km at {cons} kWh/100 km. Electricity costs €{price} per kWh, so that is {units} kWh and {total} in total. For {n} people that is {perPerson} each.

    With a return trip it is {total2}, or {perPerson2} each.
howto:
  name: "How to split charging costs"
  steps:
    - name: "Enter consumption in kWh"
      text: "Use the figure per 100 km from the on-board computer or your charging statement."
    - name: "Choose the price"
      text: "Enter the price per kWh you actually paid. Home, wallbox and fast chargers differ a lot."
    - name: "Add trip and people"
      text: "Enter distance and number of people, and decide whether the driver pays a share."
faq:
  - q: "How do I work out charging cost for a trip?"
    a: "Distance divided by 100, times consumption in kWh, times price per kWh. Then divide by the number of people."
  - q: "Which electricity price should I use?"
    a: "The price you actually paid for this trip: your home tariff, or the charger's price on the road. The example value is just a placeholder."
  - q: "Do charging losses count?"
    a: "Some energy is lost when charging. For the best figure, use consumption from your charging statement, which includes those losses."
  - q: "Can I switch between fuel and electric?"
    a: "Yes. Use the drive switch in the calculator to change between petrol or diesel and electric."
related:
  - fuel-cost-calculator
  - split-fuel-costs
  - carpool-cost-split
  - passenger-cost-calculator
---

## What is different with an electric car

The sum is the same as for a petrol car, but with different units: kilowatt-hours (kWh) instead of litres, and a price per kWh.

`distance ÷ 100 × consumption (kWh) × price per kWh`

The biggest difference is the price. It varies widely depending on where and how you charge, so enter it deliberately rather than relying on the example.

## Tips for fair charging costs

- **Real consumption:** it depends on speed, temperature and load. Recent trips are a better guide than the brochure figure.
- **Mixed charging:** if you charged both on the road and at home, use an average price or calculate the parts separately.
- **Talk openly:** cheap home charging may benefit the passengers, but it does not have to. Agree beforehand.
- **Not included:** wear, insurance and depreciation. Currency and units: euros and kilometres by default.
