---
title: "Spritkosten teilen: wer zahlt wie viel? | mitlio"
description: "Spritkosten für eine Fahrt fair teilen: vom Tankbeleg oder aus der Strecke berechnet. Mit Rechenbeispiel, kostenlos und ohne Anmeldung."
h1: "Spritkosten teilen: So wird es fair"
lead: "Du hast getankt, die anderen sind mitgefahren. Hier siehst du in Sekunden, wer wie viel bekommt."
linkLabel: "Spritkosten teilen"
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
    Ihr fahrt {km} km, das Auto braucht {cons} l/100 km, der Liter kostet {price} €. Der Sprit kostet zusammen {total}. Bei {n} Personen sind das {perPerson} pro Person.

    Kommt eine Person dazu, sinkt der Anteil auf {perPerson2}. Die Gesamtkosten bleiben bei {total2}, nur die Verteilung ändert sich.
howto:
  name: "Spritkosten in drei Schritten teilen"
  steps:
    - name: "Gesamtkosten bestimmen"
      text: "Nimm den Tankbeleg oder lass den Rechner aus Strecke, Verbrauch und Literpreis die Kosten bestimmen."
    - name: "Personen zählen"
      text: "Entscheide, ob der Fahrer einen Anteil übernimmt, und gib die Zahl der Personen ein."
    - name: "Betrag nennen"
      text: "Schicke den Betrag per Link oder WhatsApp, dann kann jede Person direkt überweisen oder bar zahlen."
faq:
  - q: "Soll ich nach Tankbeleg oder nach Strecke abrechnen?"
    a: "Der Beleg ist exakt, wenn ihr genau diese Fahrt getankt habt. Meist wurde aber vorher oder nachher getankt, dann ist die Rechnung nach Strecke und Verbrauch fairer."
  - q: "Muss der Fahrer mitzahlen?"
    a: "Üblich ist, dass der Fahrer mitzahlt: Das Auto wäre ohnehin gefahren, aber der Anteil macht die Kosten gerecht. Sprecht es vorher ab."
  - q: "Was, wenn nur ein Teil der Strecke gemeinsam gefahren wird?"
    a: "Rechne mit der Strecke, die ihr wirklich zusammen im Auto saßt. Bei einem Umweg für eine Person bietet sich ein gesonderter Betrag an."
  - q: "Wie runde ich Beträge?"
    a: "Der Rechner rundet auf den Cent und verteilt Restcents so, dass die Summe exakt stimmt. Wollt ihr krumme Beträge vermeiden, rundet ihr zugunsten des Fahrers auf."
related:
  - fahrtkostenrechner
  - fahrgemeinschaft-kosten-aufteilen
  - mitfahrer-kosten-berechnen
  - elektroauto-ladekosten-teilen
---

## Zwei Wege zum Betrag

Es gibt zwei übliche Wege, Spritkosten zu teilen.

**Nach Tankbeleg:** Du nimmst den Betrag der letzten Tankrechnung und teilst ihn. Das stimmt, wenn der Tank genau für diese Fahrt gefüllt wurde.

**Nach Strecke:** Du rechnest `Strecke ÷ 100 × Verbrauch × Literpreis`. Das ist meistens genauer, weil es nur die gemeinsame Fahrt betrachtet und nicht die Tankfüllung davor oder danach.

## Worauf du achten solltest

- **Gleicher Anteil für alle:** Jede Person zahlt gleich viel, unabhängig davon, wo sie sitzt.
- **Aktueller Literpreis:** Nimm den Preis, den du wirklich bezahlt hast, nicht den Durchschnitt.
- **Maut extra:** Gebühren trägst du im Feld „Maut & Sonstiges“ ein. Sie werden mit auf alle verteilt.
- **Schnell klären:** Nenne den Betrag direkt nach der Fahrt. Später wird es unangenehmer.
