# 🚗 AutoLog - Slimme iOS & CarPlay Rittenregistratie & Belastingdienst Export

AutoLog is een native iOS & CarPlay applicatie (SwiftUI) die automatisch je autoritten registreert zodra **Apple CarPlay** of de **Bluetooth-verbinding** van je auto start. 

Aan het einde van de maand ontvang je automatisch een officiële, **Belastingdienst-conforme rittenstaat als PDF** (inclusief begin- en eindadres, datum, tijden en km-standen) direct in je e-mailbox.

---

## 🌟 Belangrijkste Features

1. **Native Apple CarPlay Dashboard:**
   * Volledig geïntegreerd in het scherm van je auto!
   * **1-Tik Schakelen op je Dashboard:** Schakel tijdens het rijden direct op het autoscherm tussen **Zakelijk** en **Privé**.
   * Bekijk live ritstatus, startadres, afgelegde kilometers en recente ritten rechtstreeks op je CarPlay scherm.
2. **Vaste Woon- en Werkadressen (Geofencing):**
   * Stel je vaste **Woonadres (Thuis)** en **Werkadres (Kantoor / Zaak)** in.
   * Ritten tussen Thuis en Werk worden automatisch gelabeld als **Woon-werkverkeer**.
3. **Automatische Herkenning van Voertuig:**
   * Detecteert automatisch in welk voertuig je stapt (bijv. *Werkauto* vs. *Privéauto*) aan de hand van de Bluetooth- of CarPlay-naam.
4. **Strikte Scheiding & 500 km Norm Monitor:**
   * **Zakelijk (Werkauto)**
   * **Privé (Werkauto)** ➔ *Met live waarschuwingsmeter voor de fiscale 500 km bijtellingsgrens!*
   * **Privé (Privéauto)**
5. **Automatisch Begin- en Eindadres (GPS Reverse Geocoding):**
   * Zodra je vertrekt wordt je vertrekadres automatisch vastgelegd.
   * Zodra de auto uitschakelt of CarPlay verbreekt, wordt je exacte aankomstadres vastgelegd.
6. **Belastingdienst-Conforme PDF Export:**
   * Genereert een officiële A4-rittenstaat met datum, vertrektijd, aankomsttijd, **Beginadres (Vertrek)**, **Eindadres (Aankomst)**, kilometers, begin-/eindstand van de teller en ritdoel.
7. **Directe Aflevering in je Inbox:**
   * Verstuur de maandelijkse PDF met één druk op de knop, of laat 'm op de 1e van de maand automatisch via e-mail bezorgen.

---

## 📲 Installeren via SideStore / AltStore (Draadloos op je iPhone)

AutoLog heeft een officiële **SideStore Community Source**!

### SideStore Source URL:
```text
https://raw.githubusercontent.com/Ivoozz/AutoLog/main/apps.json
```

### 1-Tik Toevoegen in SideStore:
Tik op je iPhone op deze link om de source direct in SideStore te openen:  
👉 **[Open in SideStore](sidestore://source?url=https://raw.githubusercontent.com/Ivoozz/AutoLog/main/apps.json)**

*(Of ga in SideStore naar **Sources ➔ + (Voeg toe)** en plak de bovenstaande URL).*

---

## 💻 Handmatig Installeren via Sideloadly (Windows)

1. Download het `.ipa` bestand via [GitHub Releases](https://github.com/Ivoozz/AutoLog/releases).
2. Open [Sideloadly](https://sideloadly.io/), koppel je iPhone via USB.
3. Sleep `AutoLog.ipa` in Sideloadly, vul je Apple ID in en klik op **Start**.
