# 🚗 AutoLog - Slimme iOS & CarPlay Rittenregistratie & Belastingdienst Export

AutoLog is een native iOS & CarPlay applicatie (SwiftUI) die automatisch je autoritten registreert zodra **Apple CarPlay** of de **Bluetooth-verbinding** van je auto start. 

Aan het einde van de maand ontvang je automatisch een officiële, **Belastingdienst-conforme rittenstaat als PDF** (inclusief begin- en eindadres, datum, tijden en km-standen) direct in je e-mailbox.

---

## 🌟 Belangrijkste Features

1. **Native Apple CarPlay Dashboard:**
   * Volledig geïntegreerd in het scherm van je auto!
   * **1-Tik Schakelen op je Dashboard:** Schakel tijdens het rijden direct op het autoscherm tussen **Zakelijk** en **Privé**.
   * Bekijk live ritstatus, startadres, afgelegde kilometers en recente ritten rechtstreeks op je CarPlay scherm.
2. **Automatische Herkenning van Voertuig:**
   * Detecteert automatisch in welk voertuig je stapt (bijv. *Werkauto* vs. *Privéauto*) aan de hand van de Bluetooth- of CarPlay-naam.
3. **Strikte Scheiding & 500 km Norm Monitor:**
   * **Zakelijk (Werkauto)**
   * **Privé (Werkauto)** ➔ *Met live waarschuwingsmeter voor de fiscale 500 km bijtellingsgrens!*
   * **Privé (Privéauto)**
4. **Automatisch Begin- en Eindadres (GPS Reverse Geocoding):**
   * Zodra je vertrekt wordt je vertrekadres automatisch vastgelegd.
   * Zodra de auto uitschakelt of CarPlay verbreekt, wordt je exacte aankomstadres vastgelegd.
5. **Belastingdienst-Conforme PDF Export:**
   * Genereert een officiële A4-rittenstaat met datum, vertrektijd, aankomsttijd, **Beginadres (Vertrek)**, **Eindadres (Aankomst)**, kilometers, begin-/eindstand van de teller en ritdoel.
6. **Directe Aflevering in je Inbox:**
   * Verstuur de maandelijkse PDF met één druk op de knop, of laat 'm op de 1e van de maand automatisch via e-mail bezorgen.

---

## 📦 Hoe installeer je dit 100% GRATIS op je iPhone (Zonder Mac!)

Je hebt geen Mac nodig. GitHub Actions bouwt de app automatisch naar een `.ipa` bestand, waarna je 'm met Sideloadly op je iPhone zet.

### Stap 1: Download de nieuwste `.ipa`
Download de nieuwste versie vanaf de GitHub Releases:
👉 **[AutoLog Releases](https://github.com/Ivoozz/AutoLog/releases)**

### Stap 2: Installeer via Sideloadly (Windows)
1. Download en installeer het gratis tooltje [Sideloadly](https://sideloadly.io/) op je Windows PC.
2. Sluit je iPhone met het USB-kabeltje aan op je pc.
3. Sleep `AutoLog.ipa` in het grote vak in Sideloadly.
4. Vul je eigen **Apple ID** (je e-mailadres van Apple) in bij *Apple account*.
5. Klik op **Start**.
6. *Eerste keer:* Ga op je iPhone naar **Instellingen ➔ Algemeen ➔ VPN- en apparaatbeheer**, tik op je Apple ID en kies **Vertrouw**.
