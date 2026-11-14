---
title: "Fahrtkostenrechner: Kosten pro Person | mitlio"
description: "Fahrtkosten berechnen und gerecht teilen: Strecke, Verbrauch und Spritpreis eingeben, sofort sehen, was jede Person zahlt. Kostenlos und ohne Anmeldung."
h1: "Fahrtkostenrechner: Was kostet die Fahrt pro Person?"
lead: "Strecke, Verbrauch und Spritpreis eingeben. Das Ergebnis siehst du sofort, ohne Knopfdruck."
linkLabel: "Fahrtkostenrechner: Kosten pro Person"
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
    Du fährst {km} km mit {cons} l/100 km, der Liter kostet {price} €, ihr seid {n} Personen. Das sind {units} Liter und {total} Gesamtkosten. Jede Person zahlt {perPerson}.

    Mit Rückfahrt verdoppelt sich die Strecke: Dann kostet die Fahrt {total2} insgesamt, also {perPerson2} pro Person.
howto:
  name: "So berechnest du die Fahrtkosten"
  steps:
    - name: "Strecke eintragen"
      text: "Gib die einfache Strecke in Kilometern ein und schalte „Hin- und Rückfahrt“ ein, wenn ihr auch zurückfahrt."
    - name: "Verbrauch und Preis prüfen"
      text: "Trage den Verbrauch deines Autos und den aktuellen Preis pro Liter ein."
    - name: "Personen angeben"
      text: "Zähle alle mit, die im Auto sitzen, den Fahrer eingeschlossen. Entscheide, ob der Fahrer mitzahlt."
    - name: "Ergebnis teilen"
      text: "Das Ergebnis erscheint sofort. Du kannst es per Link oder WhatsApp an die Mitfahrenden schicken."
faq:
  - q: "Wie berechne ich die Fahrtkosten?"
    a: "Strecke geteilt durch 100, mal Verbrauch, mal Literpreis. Dazu kommen Maut oder Fähre. Die Summe teilst du durch die Zahl der Personen."
  - q: "Zahlt der Fahrer auch einen Anteil?"
    a: "Das entscheidet ihr. Im Rechner steht „Fahrer zahlt mit“ standardmäßig an. Schaltest du es aus, teilen sich nur die Mitfahrenden die Kosten."
  - q: "Woher kenne ich den Verbrauch meines Autos?"
    a: "Am genauesten aus deinen Tankbelegen: getankte Liter geteilt durch gefahrene Kilometer, mal 100. Der Bordcomputer liefert meist einen brauchbaren Näherungswert."
  - q: "Sind Verschleiß und Versicherung eingerechnet?"
    a: "Nein, der Rechner nutzt nur Sprit und das, was du unter „Maut & Sonstiges“ einträgst. Wollt ihr Verschleiß mitzahlen, rechnet einen Betrag dort ein."
  - q: "Werden meine Eingaben gespeichert?"
    a: "Nein. Die Berechnung läuft in deinem Browser, es werden keine Daten gesendet. Die Werte stehen nur in der Adresszeile, damit du das Ergebnis teilen kannst."
related:
  - spritkosten-teilen
  - mitfahrer-kosten-berechnen
  - fahrgemeinschaft-kosten-aufteilen
  - kilometerpauschale-rechner
---

## So rechnest du

Die Fahrtkosten bestehen aus drei Teilen: dem Sprit, eventuell Maut oder Fähre und, wenn ihr das wollt, einem Beitrag für den Verschleiß.

Der Sprit ergibt sich aus einer einfachen Formel:

`Strecke ÷ 100 × Verbrauch × Preis pro Liter`

Diese Summe teilst du durch die Zahl der Personen. Der Rechner oben erledigt das und rundet auf den Cent, sodass die Einzelbeträge zusammen genau die Gesamtkosten ergeben.

## Tipps für eine faire Abrechnung

- **Sprecht vorher ab**, wer wie viel zahlt. Das verhindert Diskussionen nach der Fahrt.
- **Nimm den echten Verbrauch.** Autobahn mit voller Beladung verbraucht mehr als die Herstellerangabe.
- **Rechne Hin- und Rückfahrt zusammen**, wenn ihr denselben Weg zurückfahrt.
- **Zähle den Fahrer mit**, wenn er sowieso gefahren wäre: Dann zahlt jeder den gleichen Anteil.
