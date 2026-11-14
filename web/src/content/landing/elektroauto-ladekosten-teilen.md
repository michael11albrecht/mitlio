---
title: "Elektroauto-Ladekosten teilen und berechnen | mitlio"
description: "Ladekosten einer Fahrt mit dem Elektroauto fair teilen: kWh pro 100 km und Strompreis eingeben, Anteil pro Person sehen. Kostenlos, ohne Anmeldung."
h1: "Elektroauto: Ladekosten fair teilen"
lead: "Strom statt Sprit: Gib Verbrauch in kWh und deinen Strompreis ein und sieh, was jede Person zahlt."
linkLabel: "Elektroauto-Ladekosten teilen"
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
    Du fährst {km} km mit {cons} kWh/100 km. Der Strom kostet {price} € pro kWh. Das sind {units} kWh und {total} Gesamtkosten. Für {n} Personen sind das {perPerson} pro Person.

    Mit Rückfahrt sind es {total2}, also {perPerson2} pro Person.
howto:
  name: "So teilst du Ladekosten"
  steps:
    - name: "Verbrauch in kWh eintragen"
      text: "Nimm den Verbrauch pro 100 km aus dem Bordcomputer oder deiner Ladeabrechnung."
    - name: "Strompreis wählen"
      text: "Trage den Preis pro kWh ein, den du tatsächlich zahlst. Zuhause, an der Wallbox und an Schnellladern ist er sehr verschieden."
    - name: "Personen und Strecke angeben"
      text: "Gib Strecke und Personenzahl an und entscheide, ob der Fahrer mitzahlt."
faq:
  - q: "Wie rechne ich Ladekosten pro Fahrt aus?"
    a: "Strecke geteilt durch 100, mal Verbrauch in kWh, mal Preis pro kWh. Die Summe teilst du durch die Zahl der Personen."
  - q: "Welchen Strompreis nehme ich?"
    a: "Den, den du für diese Fahrt tatsächlich gezahlt hast. Beim Laden zu Hause ist es dein Tarif, unterwegs der Preis der Ladesäule. Der Beispielwert ist nur ein Platzhalter."
  - q: "Zählen Ladeverluste mit?"
    a: "Beim Laden geht ein Teil der Energie verloren. Nimm als Verbrauch am besten den Wert aus der Ladeabrechnung, dann sind diese Verluste enthalten."
  - q: "Kann ich zwischen Benzin und Strom wechseln?"
    a: "Ja. Mit dem Schalter „Antrieb“ im Rechner wechselst du zwischen Benzin oder Diesel und Elektro."
related:
  - fahrtkostenrechner
  - spritkosten-teilen
  - fahrgemeinschaft-kosten-aufteilen
  - mitfahrer-kosten-berechnen
---

## Was beim Elektroauto anders ist

Die Rechnung ist dieselbe wie beim Verbrenner, nur mit anderen Einheiten: Statt Litern zählst du Kilowattstunden (kWh), statt des Literpreises nimmst du den Preis pro kWh.

`Strecke ÷ 100 × Verbrauch (kWh) × Preis pro kWh`

Der größte Unterschied ist der Preis. Er schwankt stark, je nachdem, wo und wie du lädst. Deshalb solltest du ihn bewusst eintragen, statt dich auf den Vorschlag zu verlassen.

## Tipps für faire Ladekosten

- **Echter Verbrauch:** Er hängt von Tempo, Temperatur und Beladung ab. Der Wert aus den letzten Fahrten ist besser als die Herstellerangabe.
- **Gemischte Ladung:** Wurde unterwegs und zu Hause geladen, nimm einen Durchschnittspreis oder rechne beide Anteile getrennt.
- **Offen sprechen:** Wenn du zu Hause günstig lädst, dürfen die Mitfahrenden davon profitieren, müssen es aber nicht. Klärt es vorher.
- **Nicht vergessen:** Verschleiß, Versicherung und Abschreibung sind nicht enthalten.
