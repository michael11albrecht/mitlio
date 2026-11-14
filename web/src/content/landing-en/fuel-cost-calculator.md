---
title: "Fuel Cost Calculator: Cost per Person | mitlio"
description: "Work out what a car trip costs and what each person owes: enter distance, consumption and fuel price. Free, no sign-up, no ads."
h1: "Fuel cost calculator: what does the trip cost per person?"
lead: "Enter distance, consumption and fuel price. The result appears instantly, no button needed."
linkLabel: "Fuel cost calculator: cost per person"
de: fahrtkostenrechner
example:
  input:
    distanceKm: 250
    consumptionPer100km: 6.5
    pricePerUnit: 1.8
    persons: 3
    driverPays: true
  compare:
    roundTrip: true
  text: |
    You drive {km} km at {cons} l/100 km, fuel costs €{price} per litre, and there are {n} of you. That is {units} litres and {total} in total, so each person pays {perPerson}.

    With a return trip the distance doubles: the trip then costs {total2}, or {perPerson2} each.
howto:
  name: "How to work out the trip cost"
  steps:
    - name: "Enter the distance"
      text: "Type the one-way distance in kilometres and switch on round trip if you drive back the same way."
    - name: "Check consumption and price"
      text: "Enter your car's consumption and the price per litre you actually paid."
    - name: "Count everyone in the car"
      text: "Include the driver, then decide whether the driver pays a share too."
    - name: "Share the result"
      text: "Send the amount to your passengers with a link or a message."
faq:
  - q: "How do I calculate fuel cost for a trip?"
    a: "Distance divided by 100, times consumption, times price per litre. Add tolls or ferries, then divide by the number of people."
  - q: "Should the driver pay a share?"
    a: "That is up to you. The driver pays a share by default; switch it off and only the passengers split the cost."
  - q: "Where do I find my car's consumption?"
    a: "The most accurate source is your own refuelling: litres filled divided by kilometres driven, times 100. The on-board computer is usually a decent estimate."
  - q: "Does it include wear, insurance or depreciation?"
    a: "No. Only fuel and whatever you add under tolls and extras. If you want to cover wear, add an amount there."
  - q: "Is my data stored?"
    a: "No. The calculation runs in your browser and nothing is sent. Your numbers appear only in the address bar so you can share the result."
related:
  - split-fuel-costs
  - passenger-cost-calculator
  - carpool-cost-split
  - mileage-rate-calculator
---

## How the calculation works

A trip cost has up to three parts: fuel, tolls or ferries, and, if you choose, a contribution towards wear on the car. Fuel follows a simple formula:

`distance ÷ 100 × consumption × price per litre`

Divide the total by the number of people. The calculator does this for you and rounds to the cent, so the individual amounts add up exactly to the total.

## Units and currency

The calculator uses kilometres, litres and euros by default. The numbers work with any currency: enter your local fuel price and read the result in that currency. Miles and gallons are not supported yet.

## Tips for a fair split

- **Agree before you leave** who pays what. It avoids awkward talk later.
- **Use real consumption.** Motorway driving with a full car uses more than the manufacturer figure.
- **Count the return trip** if you drive the same way back.
