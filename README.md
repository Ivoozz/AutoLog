# 🚗 AutoLog - Slimme iOS & CarPlay Rittenregistratie & Belastingdienst Export

AutoLog is een native iOS & CarPlay applicatie (SwiftUI) die automatisch je autoritten registreert zodra **Apple CarPlay** of de **Bluetooth-verbinding** van je auto start.

Aan het einde van de maand ontvang je automatisch een officiële, **Belastingdienst-conforme rittenstaat als PDF** (inclusief begin- en eindadres, datum, tijden en km-standen) direct in je e-mailbox via Gmail SMTP.

---

## 📲 Installeren via AltStore PAL / AltStore / SideStore

AutoLog beschikt over een officiële source die compatibel is met **AltStore PAL** (EU Marketplace), **AltStore Classic** en **SideStore**!

### 🔘 1-Tik Direct Toevoegen:

Kies jouw app en tik op de bijbehorende knop vanaf je iPhone:

| Store | Directe Toevoeg-knop |
| :--- | :--- |
| **AltStore PAL (EU)** | [![Open in AltStore PAL](https://img.shields.io/badge/Open%20in-AltStore%20PAL-3B86F7?style=for-the-badge&logo=apple&logoColor=white)](altstore-pal://source?url=https%3A%2F%2Fraw.githubusercontent.com%2FIvoozz%2FAutoLog%2Fmain%2Fsource.json) |
| **AltStore (Classic)** | [![Open in AltStore](https://img.shields.io/badge/Open%20in-AltStore-2997ff?style=for-the-badge&logo=apple&logoColor=white)](altstore://source?url=https%3A%2F%2Fraw.githubusercontent.com%2FIvoozz%2FAutoLog%2Fmain%2Fsource.json) |
| **SideStore** | [![Open in SideStore](https://img.shields.io/badge/Open%20in-SideStore-5856D6?style=for-the-badge&logo=apple&logoColor=white)](sidestore://source?url=https%3A%2F%2Fraw.githubusercontent.com%2FIvoozz%2FAutoLog%2Fmain%2Fapps.json) |

---

### 📋 Handmatig Source Toevoegen in AltStore PAL:

1. Open **AltStore PAL** op je iPhone.
2. Ga onderin naar het tabblad **Sources** (Bronnen).
3. Tik rechtsboven op de **`+` (Plusknop)**.
4. Plak de volgende officiële Source URL in en tik op **Add**:
   ```text
   https://raw.githubusercontent.com/Ivoozz/AutoLog/main/source.json
   ```
5. Zoek naar **AutoLog** in het **Browse**-overzicht en tik op **Install**!

> **Alternatieve PAL URL:**  
> `https://raw.githubusercontent.com/Ivoozz/AutoLog/main/PALSource.json`

---

## 💻 Handmatig Installeren via Sideloadly (Windows / Mac)

Als je liever rechtstreeks via USB/Wi-Fi sideload:
1. Download de nieuwste `AutoLog-vX.X.X.ipa` via [GitHub Releases](https://github.com/Ivoozz/AutoLog/releases).
2. Open [Sideloadly](https://sideloadly.io/) en sluit je iPhone aan.
3. Sleep het `.ipa` bestand in Sideloadly, vul je Apple ID in en klik op **Start**.

---

## 🌟 Belangrijkste Features

1. **🏝️ Live Activities & Dynamic Island Cockpit:**
   * Zodra CarPlay of de Bluetooth-carkit verbindt, verschijnt er automatisch een interactieve Live Activity op je vergrendelscherm.
   * Realtime kilometerteller in grote **SF Pro Rounded** typografie, stopwatch en actuele ritstatus (**`🏢 Zakelijk`** vs **`👤 Privé`**).
   * Live status in het **Dynamic Island** met pulserend route-icoon en directe km-weergave.

2. **🚗 Automatische Ritdetectie (CarPlay & Bluetooth):**
   * Start en stopt automatisch zodra je instapt of het contact uitzet.
   * Herkent automatisch in welk voertuig je stapt (bijv. *Werkauto* vs. *Privéauto*).

3. **📍 Woon- en Werkherkenning (Geofencing & GPS Resolving):**
   * Stel je vaste **Thuislocatie** en **Kantoor / Werklocatie** in via de 1-tik GPS ophaalknop.
   * Ritten tussen Thuis en Werk worden automatisch gelabeld als **Woon-werkverkeer**.
   * Exacte straatnamen en huisnummers worden automatisch via Apple CoreLocation reverse geocoding achterhaald.

4. **⚠️ 500 km Norm Bijtellingsbewaker:**
   * Live meter voor privé gereden kilometers in de zakelijke auto.
   * Voorkomt onaangename fiscale verrassingen bij de Belastingdienst.

5. **📄 Belastingdienst-Conforme PDF Export:**
   * Genereert een officiële A4-rittenstaat met datum, vertrektijd, aankomsttijd, beginadres, eindadres, km-standen en ritdoel.
   * Automatische maandelijkse aflevering direct via **Gmail SMTP over TLS** (`smtp.gmail.com:465`).

6. **💎 iOS 26+ Liquid Glass UI:**
   * Volledig opgebouwd met translucente frosted glassmorphism (`.ultraThinMaterial`), subtiele glazen randreflecties en een dynamische ambient mesh aura.
