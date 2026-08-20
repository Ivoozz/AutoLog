# 🚗 AutoLog - Slimme iOS Rittenregistratie & Belastingdienst Export

AutoLog is een native iOS applicatie (SwiftUI) die automatisch je autoritten registreert zodra **Apple CarPlay** of de **Bluetooth-verbinding** van je auto start. 

Aan het einde van de maand ontvang je automatisch een officiële, **Belastingdienst-conforme rittenstaat als PDF** direct in je e-mailbox.

---

## 🌟 Belangrijkste Features

1. **Automatische Herkenning van Voertuig & CarPlay:**
   - Detecteert automatisch in welk voertuig je stapt (bijv. *Werkauto* vs. *Privéauto*) aan de hand van de Bluetooth- of CarPlay-naam.
2. **Strikte Scheiding & 500 km Norm Monitor:**
   - **Zakelijk (Werkauto)**
   - **Privé (Werkauto)** ➔ *Met live waarschuwingsmeter voor de fiscale 500 km bijtellingsgrens!*
   - **Privé (Privéauto)**
3. **1-Tik Quick Switch:**
   - Zit je in de werkauto voor een privéritje? Wissel met één tik op het dashboard of de actieve ritkaart direct tussen Zakelijk en Privé.
4. **Belastingdienst-Conforme PDF Export:**
   - Genereert een A4-rittenstaat met datum, tijden, vertrek- en aankomstadressen (automatisch via GPS Reverse Geocoding), gereden kilometers, kilometerteller begin-/eindstanden en ritdoelen.
5. **Directe Aflevering in je Inbox:**
   - Verstuur de maandelijkse PDF met één druk op de knop, of laat 'm op de 1e van de maand automatisch via de ingebouwde e-mailservice bezorgen.

---

## 📦 Hoe installeer je dit 100% GRATIS op je iPhone (Zonder Mac!)

Je hebt geen Mac nodig. We gebruiken **GitHub Actions** als onze gratis cloud-Mac om de app te compileren, en **Sideloadly** op je Windows-pc om de app op je iPhone te zetten.

### Stap 1: Zet de code in een (privé of publieke) GitHub Repo
Open je terminal / console en voer uit:

```bash
cd /root/agy-dashboard/AutoLog
git init
git add .
git commit -m "Initial commit of AutoLog iOS App"
git branch -M main
# Koppel aan jouw GitHub account (maak eerst een nieuwe lege repo aan op github.com):
git remote add origin https://github.com/JOUW_GEBRUIKERSNAAM/AutoLog.git
git push -u origin main
```

### Stap 2: Download het `.ipa` Installatiebestand
1. Ga op **GitHub.com** naar jouw repository.
2. Klik bovenaan op het tabblad **Actions**.
3. De workflow `Build iOS IPA (AutoLog)` start direct automatisch op een virtuele macOS-server.
4. Zodra het groene vinkje verschijnt (na ~3 minuten), klik je op de build en download je het bestand onder **Artifacts** (`AutoLog-iOS-App.zip`).
5. Pak het zip-bestand uit op je computer; je hebt nu `AutoLog.ipa`.

### Stap 3: Installeer via Sideloadly (Windows)
1. Download en installeer het gratis tooltje [Sideloadly](https://sideloadly.io/) op je Windows PC.
2. Sluit je iPhone met het USB-kabeltje aan op je pc (en tik op je iPhone op "Vertrouw deze computer" indien gevraagd).
3. Open Sideloadly:
   - Sleep `AutoLog.ipa` in het grote vak in Sideloadly.
   - Vul je **Apple ID** (je gewone e-mailadres van Apple) in bij *Apple account*.
   - Klik op **Start**.
4. Binnen 30 seconden staat de **AutoLog** app op het beginscherm van je iPhone!
5. *Eerste keer openen op je iPhone:* Ga naar **Instellingen ➔ Algemeen ➔ VPN- en apparaatbeheer**, tik op je Apple ID en kies **Vertrouw**.

---

## ⚙️ Ingebouwde iOS CarPlay Automatisering (Optioneel & Aanbevolen)

Wil je dat de app 100% betrouwbaar ontwaakt zodra CarPlay start?
1. Open de app **Opdrachten (Shortcuts)** op je iPhone.
2. Tik onderaan op **Automatisering** ➔ Tik op de **+** (Nieuwe automatisering).
3. Kies **CarPlay** ➔ Selecteer **Verbindt**.
4. Zet **Voer direct uit** aan (zonder te vragen).
5. Voeg actie toe: zoek op **AutoLog** en kies **Start Rittenregistratie**.
6. *(Optioneel)* Maak een tweede automatisering voor wanneer CarPlay verbreekt ➔ kies **Stop Rittenregistratie**.

---

## 🚢 Structuur van het Project

- `project.yml`: Declaratieve configuratie voor XcodeGen.
- `.github/workflows/build-ipa.yml`: Cloud CI/CD build pipeline op Apple Silicon macOS.
- `AutoLog/Models/`: Datamodellen (`Vehicle`, `Trip`, `TripType`, `UserSettings`).
- `AutoLog/Services/`:
  - `TripDetectionEngine.swift`: Coördinatie tussen Bluetooth/CarPlay triggers en locatieregistratie.
  - `LocationManager.swift`: Nauwkeurige GPS-tracking op de achtergrond met filtering.
  - `BluetoothManager.swift`: Detectie van auto-audio routes en Bluetooth apparaten.
  - `PDFReportGenerator.swift`: Belastingdienst-proof A4 PDF-renderer via PDFKit.
  - `MailDispatcherService.swift`: Directe mailaflevering naar je inbox.
- `AutoLog/Views/`: Moderne SwiftUI dashboards, rittenlijsten, live kaarten en instellingen.
- `AutoLog/Intents/`: AppIntents voor Siri Shortcuts en CarPlay automatiseringen.
