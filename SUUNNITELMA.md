# DIAGSTICK – suunnitelma

USB:n kautta kytkettävä NVMe-levy tietokonehuollon yleistyökaluksi. Tikulta
käynnistetään live-järjestelmiä, ajetaan siirrettäviä (portable) ohjelmia
asennetusta Windowsista ja ajetaan omia skriptejä, jotka tekevät
vianmäärityksen, korjaukset ja raportoinnin samalla tavalla joka kerta.

---

## 1. Laitteisto

| Osa | Valinta | Perustelu |
|---|---|---|
| Levy | 1–2 TB NVMe, TLC, DRAM-välimuisti (esim. Samsung 990 Pro, WD SN850X, Crucial T500) | ISO-kuvat, ajuripaketit ja asiakkaiden varmuuskopiot vievät tilaa. TLC kestää kirjoituksia paremmin kuin QLC. |
| Kotelo | USB 3.2 Gen2 (10 Gbit/s), **Realtek RTL9210B** -piiri, tai USB4/TB-kotelo (ASM2464PD) | RTL9210B käynnistää luotettavasti vanhoistakin koneista, tukee UASP:ta ja välittää SMART-tiedot. JMS583-piirissä on yhteensopivuusongelmia. |
| Kaapelit | USB-C–C ja USB-C–A, lyhyet (≤ 30 cm) | Vanhoissa koneissa on vain USB-A-portteja. |
| Lisäksi | Pieni USB-tikku, jossa on **fyysinen kirjoitussuojakytkin** (esim. Kanguru), sekä varakopio Ventoysta | NVMe-koteloissa ei käytännössä ole kirjoitussuojaa. Kirjoitussuojattu tikku on varakeino saastuneisiin koneisiin. |
| Lämpö | Alumiinikotelo ja lämpötyyny | Pitkät kopioinnit kuumentavat levyä ja hidastavat sitä. |

---

## 2. Osiointi

Pohjana on **Ventoy**, jossa on varattu tilaa omille osioille (`-r` / *Reserve space*).

| # | Nimi | Tiedostojärjestelmä | Koko (2 TB) | Sisältö |
|---|---|---|---|---|
| 1 | `VENTOY` | exFAT | 100 GB | ISO-, WIM-, VHD(X)- ja IMG-kuvat sekä `ventoy/ventoy.json` |
| 2 | `VTOYEFI` | FAT16 | 32 MB | Ventoyn käynnistyslatain (luodaan automaattisesti) |
| 3 | `TOOLS` | NTFS | 250 GB | Portable-ohjelmat, skriptit, ajurit, offline-asennuspaketit ja dokumentaatio |
| 4 | `CASES` | NTFS + BitLocker *tai* VeraCrypt | loput (~1,5 TB) | Asiakkaiden varmuuskopiot ja raportit, **aina salattuna** |
| 5 | `LINUX` | ext4 | 100 GB | Pysyvä tallennus (persistence) Linux-liveille, `ddrescue`-kuvat ja -lokit |

Secure Boot: Ventoyn `ENROLL_THIS_KEY_IN_MOKMANAGER.cer` rekisteröidään koneisiin
tarvittaessa. Muuten Secure Boot otetaan väliaikaisesti pois päältä ja
**laitetaan takaisin päälle** ennen luovutusta (kirjataan tarkistuslistaan).

---

## 3. Live- ja käynnistyskuvat (`VENTOY`-osio)

Jokaiseen tehtävään yksi **ensisijainen** ja yksi **vara**. Kaikki ladataan
`stick.csv`-luettelon perusteella (ks. luku 5.8).

| Tehtävä | Ensisijainen | Vara |
|---|---|---|
| Windows-ympäristö tikulta | Hiren's BootCD PE | oma WinPE (vaihe 4) |
| Windowsin asennus | Windows 11 -ISO (virallinen) | – |
| Linux-yleistyökalu (ddrescue, smartctl, GParted, chntpw, nmap) | SystemRescue | Ubuntu LTS Live |
| Levykuva ja kloonaus | Rescuezilla | `ddrescue`/`partclone` SystemRescuessa |
| Muistitesti | Memtest86+ | Windowsin muistintarkistus |
| Virustorjunta tikulta | ESET SysRescue Live | KVRT Hiren'sissä |
| Levyn tyhjennys | ShredOS | `nvme sanitize` / `hdparm` SystemRescuessa |
| Kaikki muu | netboot.xyz | – |

Pudotettu: Windows 10 (kuluttajien ESU päättyy 13.10.2026), Fedora,
GParted Live ja Clonezilla (sisältyvät SystemRescueen ja Rescuezillaan),
PassMark MemTest86, Ultimate Boot CD, Kaspersky Rescue Disk, ChromeOS Flex, Kali
ja Windows 11 VHDX. Lisätään takaisin, jos jotain oikeasti kaivataan.

Valmistajien diagnostiikka (Lenovo, Dell, HP, Seagate) ajetaan koneen omasta
BIOSista tai ladataan tarvittaessa. Niitä ei pidetä tikulla.

Kuvien yhteiskoko on noin 20 GB. 1 TB:n levy riittää hyvin, ja suurin osa tilasta jää varmuuskopioille.

---

## 4. Portable-ohjelmat (`TOOLS\Portable`)

| Luokka | Ensisijainen | Vara |
|---|---|---|
| Järjestelmätiedot, lämpötilat | HWiNFO | Sysinternals Suite (Autoruns, Process Explorer, TCPView) |
| Levyjen kunto | CrystalDiskInfo | `smartctl` SystemRescuessa |
| Tietojen palautus | TestDisk/PhotoRec | DMDE |
| Rasitustesti | OCCT | Memtest86+ (RAM) |
| Haittaohjelmat | KVRT | Microsoft Safety Scanner (`msert`) + AdwCleaner mainosohjelmiin |
| Ajurit | valmistajan työkalu | Snappy Driver Installer Origin, DDU näytönohjaimille |
| Etätuki | RustDesk | Windowsin Pikatuki (Quick Assist) |
| Salasanat ja avaimet | KeePassXC | – |
| Asennustikut | Rufus | Ventoy |

Pudotettu, koska Windows tai muut työkalut kattavat ne: CPU-Z, GPU-Z,
HWMonitor, Speccy, osiointityökalut (Levynhallinta / GParted), 7-Zip
(Windows 11 avaa 7z- ja rar-paketit), Notepad++, Everything, levytilan
analyysityökalut, verkkoskannerit (nmap SystemRescuessa), lisävirusskannerit,
Windowsin korjausohjelmat (DISM ja `sfc` skripteinä) ja selaimet.

---

## 5. Skriptit (`TOOLS\Scripts`) – projektin varsinainen ydin

Kaikki skriptit kirjoittavat lokin ja raportin kansioon `CASES:\<tikettinumero>\`.
Yhteinen kirjasto löytää tikun osiot **levyn nimen (labelin)** perusteella, ei kirjaintunnuksen perusteella.

### 5.1 Käynnistys ja valikko
| Skripti | Tehtävä |
|---|---|
| `Start.cmd` / `Start.ps1` | **Toteutettu.** Pyytää järjestelmänvalvojan oikeudet, kysyy tiketin, luo tapauskansion CASES-osiolle ja listaa `Scripts`-kansion skriptit sekä toimintaohjeet, työkalukansion ja tapauskansion |
| `winpe\startnet.cmd` | WinPE:n käynnistys: verkko päälle, osiot labelin perusteella, valikko |

### 5.2 Vastaanotto ja inventaario
| Skripti | Tehtävä |
|---|---|
| `Intake-Report.ps1` | **Toteutettu.** Tekstiraportti: valmistaja, malli, sarjanumero, BIOS, CPU, RAM, levyt ja niiden kuluminen, osiot, **BitLocker-palautusavaimet** (tallentuvat salatulle CASES-osiolle), Secure Boot, aktivointi, laitteet, joissa on virhe, järjestelmälokin yleisimmät virheet, akkuraportti ja asennetut ohjelmat. |
| `Export-Logs.ps1` | Tapahtumalokit (System/Application, 30 vrk), Reliability History, minidumpit, `setupapi`, WER |

### 5.3 Vianmääritys
| Skripti | Tehtävä |
|---|---|
| `Disk-Health.ps1` | `smartctl` kaikille levyille ja tulkinta (relocated/pending sectors, NVMe-kulumisprosentti) liikennevalona |
| `Mem-Test-Schedule.ps1` | Ajastaa Windows Memory Diagnosticin ja lukee tuloksen seuraavalla käynnistyskerralla |
| `Stress-Quick.ps1` | 10 minuutin CPU/GPU/RAM-rasitus (OCCT CLI / y-cruncher) ja lämpötilojen loki |
| `Net-Diag.ps1` | IP-asetukset, DNS, gateway-ping, `tracert`, nopeustesti, Wi-Fi-raportti (`netsh wlan show wlanreport`) |
| `BSOD-Analyze.ps1` | Kerää minidumpit ja ajaa `kd`/BlueScreenView-tulkinnan |

### 5.4 Korjaus
| Skripti | Tehtävä |
|---|---|
| `Repair-System.ps1` | `DISM /RestoreHealth` → `sfc /scannow` → `chkdsk` -ajastus, tulokset raporttiin |
| `Reset-WindowsUpdate.ps1` | Palvelut pois, SoftwareDistribution/catroot2 uusiksi, palvelut päälle |
| `Reset-Network.ps1` | Winsock, TCP/IP, DNS-välimuisti, proxy ja verkkoadapterin uudelleenasennus |
| `Reset-Spooler.ps1`, `Reset-Store.ps1`, `Reset-IconCache.ps1` | Yleiset pikakorjaukset |
| `Cleanup.ps1` | Väliaikaistiedostot, `cleanmgr`-profiili ja komponenttisäilö (`/StartComponentCleanup`) |
| `winpe\Repair-Boot.cmd` | `bootrec`, `bcdboot`, ESP:n uudelleenluonti, offline-`sfc`/`DISM` |
| `Malware-Sweep.ps1` | Ajaa RKillin, KVRT:n, ADWCleanerin ja `msert`in peräkkäin ja kerää lokit, sitten Autoruns-vertailun |

### 5.5 Varmuuskopio ja siirto
| Skripti | Tehtävä |
|---|---|
| `Backup-UserData.ps1` | Robocopy: käyttäjäprofiilit (Työpöytä, Tiedostot, Kuvat jne.), selainprofiilit, Outlookin PST/OST-sijainnit, Sticky Notes, fontit, Wi-Fi-profiilit (`netsh wlan export`), tulostimet, asennettujen ohjelmien lista, lisenssiavaimet. Lisäksi SHA256-manifesti. |
| `Restore-UserData.ps1` | Palauttaa edellisen uudelle koneelle tai asennukselle ja vertaa manifestiin |
| `Backup-Offline.sh` | Linux-livestä: Windows-levy vain luku -tilassa ja `rsync` CASES-osioon (kun Windows ei käynnisty) |
| `Image-Disk.sh` | `ddrescue`-kääre: kuva viallisesta levystä, `mapfile` ja jatkaminen keskeytyksestä |

### 5.6 Asennuksen jälkeen
| Skripti | Tehtävä |
|---|---|
| `PostInstall.ps1` | Profiilin mukainen `winget import` (perus, toimisto, pelaaja), ajurit SDIO:lla/valmistajan työkalulla, Windows Update, virta-asetukset, palautuspiste |
| `Debloat.ps1` | Maltillinen esiasennettujen sovellusten poisto, ei järjestelmää rikkovia muutoksia |
| `Handoff-Checklist.ps1` | Tarkistaa ennen luovutusta: Secure Boot päällä, BitLocker/laitesalaus palautettu, aktivointi OK, päivitykset ajettu, väliaikaiset tunnukset poistettu ja huoltotyökalut siivottu |

### 5.7 Tyhjennys
| Skripti | Tehtävä |
|---|---|
| `Wipe-Disk.sh` | Tunnistaa levytyypin: NVMe → `nvme sanitize` / `format --ses`, SATA SSD → `hdparm --security-erase`, HDD → `nwipe`. Tarkistaa jälkikäteen otoksin ja tuottaa **tyhjennystodistuksen** (PDF/HTML: sarjanumero, menetelmä, aika, tekijä). |

### 5.8 Tikun ylläpito
| Skripti | Tehtävä |
|---|---|
| `Build-Stick.ps1` | **Toteutettu.** Lataa kaiken `stick.csv`:n mukaan TOOLS- ja VENTOY-osioille (uudelleenajo = päivitys) ja kirjoittaa `SHA256SUMS.csv`:n. `-Verify` vertaa osioita siihen. Korvaa aiemmat Update-Tools-, Update-ISOs- ja Verify-Integrity-skriptit. |
| `Build-WinPE.ps1` | Rakentaa oman WinPE:n ADK:lla, lisää ajurit, PowerShellin ja valikon |
| `Gen-VentoyJson.ps1` | Tuottaa `ventoy.json`-tiedoston: valikkoaliakset, luokat, teema ja autoinstall-liitokset |
| `Purge-Cases.ps1` | Poistaa tapaukset, jotka ovat vanhempia kuin säilytysaika (esim. 30 vrk luovutuksesta), ja kirjaa poistot |

`stick.csv`: sarakkeet `Target` (TOOLS/VENTOY), `Dest` ja `Url`.
- Jos `Dest`:llä on tiedostopääte, ladattu tiedosto tallennetaan sellaisenaan. Jos päätettä ei ole, zip-paketti puretaan kansioksi.
- `Url` on joko suora osoite, `github:omistaja/repo <regex>` (GitHubin uusimman julkaisun tiedosto) tai `manual:<sivu>`. Käsin ladattavat rivit skripti vain tulostaa.

**Tikku nollasta:** asenna Ventoy2Disk varattua tilaa jättäen → luo osiot
`TOOLS` ja `CASES` (NTFS) Levynhallinnassa → kloonaa tämä repo `TOOLS:\`-juureen →
aja `Scripts\Build-Stick.ps1` → hae `manual:`-rivit käsin → aja skripti uudelleen,
jotta tiivisteet päivittyvät.

## 6. Muu sisältö (`TOOLS`)

- **Ajurit/**: Intel RST/VMD (Windows-asennus ei näe levyä ilman niitä), Realtek/Intel/Killer-verkkoajurit,
  USB-C/Thunderbolt-ajurit, SDIO-ajuripaketit, valmistajien ajurityökalut (Lenovo System Update, Dell Command Update,
  HP Image Assistant).
- **Offline-asennuspaketit/**: VC++ Redistributable AIO, .NET-ajonaikaiset kirjastot, DirectX End-User Runtime,
  Office Deployment Tool + konfiguraatiot, selainten MSI-asennuspaketit, LibreOffice.
- **Konfiguraatiot/**: `autounattend.xml`-variantit, `winget`-profiilit, OCCT-testiprofiilit, virtasuunnitelmat.
- **Dokumentaatio/**: BIOS- ja käynnistysvalikkonäppäimet valmistajittain, BitLocker-palautusavaimen etsintäohjeet
  (Microsoft-tili, AD/Entra), tavallisimmat virhekoodit, tarkistuslistat (vastaanotto, luovutus, tyhjennys),
  asiakkaan suostumuslomake (tietojen käsittely, salasanat, tyhjennys).
- **Raporttipohjat/**: HTML-pohja vastaanottoraportille, huoltoraportille ja tyhjennystodistukselle.
- **Avaimet/**: KeePassXC-tietokanta (tuoteavaimet), ei koskaan selväkielisiä tiedostoja.

---

## 7. Hakemistorakenne

```
VENTOY:\
├── ISO\
│   ├── 1-WinPE\           (Hiren's, myöhemmin oma WinPE)
│   ├── 2-Windows\         (Win11)
│   ├── 3-Linux\           (SystemRescue, Ubuntu)
│   ├── 4-Backup\          (Rescuezilla)
│   ├── 5-Diag\            (Memtest86+)
│   ├── 6-Antivirus\       (ESET SysRescue)
│   ├── 7-Wipe\            (ShredOS)
│   └── 8-Muut\            (netboot.xyz)
└── ventoy\
    ├── ventoy.json
    ├── autounattend\
    └── theme\

TOOLS:\
├── Start.cmd
├── Portable\<luokka>\<ohjelma>\
├── Scripts\
│   ├── lib\
│   ├── intake\  diag\  repair\  backup\  postinstall\  wipe\  maintenance\
│   ├── winpe\
│   └── linux\
├── Drivers\
├── Offline-Installers\
├── Configs\
├── Docs\Playbooks.md      (toimintaohjeet oireittain)
├── Templates\
├── stick.csv              (mitä tikulle ladataan)
└── SHA256SUMS.csv         (Build-Stick.ps1:n tuottama)

CASES:\  (salattu)
└── <VVVV-KK-PP>_<tiketti>\
    ├── intake\   logs\   backup\   reports\
    └── case.json
```

Tämä Git-repositorio sisältää `TOOLS`-osion **skriptit, konfiguraatiot, dokumentaation,
pohjat ja `stick.csv`:n**. Binäärit ja ISO-kuvat eivät kuulu repositorioon, vaan
`Build-Stick.ps1` hakee ne.

---

## 8. Tietoturva ja tietosuoja

- **Tikku itse on riski.** Se kytketään saastuneisiin koneisiin. Siksi:
  automaattinen käynnistys on pois päältä, `Build-Stick.ps1 -Verify` ajetaan
  puhtaalla koneella jokaisen haittaohjelmatapauksen jälkeen, tikku voidaan rakentaa
  uudelleen tyhjästä (luku 5.8), ja vakavat
  saastunnat käsitellään **livestä**, ei asennetusta Windowsista.
- **GDPR:** asiakkaan tiedot tallennetaan vain salattuun `CASES`-osioon, niille
  määritellään säilytysaika (`Purge-Cases.ps1`) ja käsittelystä pyydetään
  kirjallinen suostumus. Asiakkaan salasanoja ei tallenneta.
- **Salasanojen nollaus ja tunnusten ohitus** (esim. `chntpw`) vain laitteen
  todennetun omistajan pyynnöstä, ja toimenpide kirjataan.
- **Lisenssit:** tikku on yksityiskäytössä, joten ilmaisversiot riittävät
  eikä lisenssejä tarvitse seurata.
- **Vain tunnetut lähteet.** Ei krakattuja ohjelmia eikä "kaiken sisältäviä"
  kokoelmia, joiden sisällöstä ei ole varmuutta (esim. osa Medicat-/Strelec-sisällöstä):
  ne ovat yleinen haittaohjelmien levitysreitti. Kaikki ladataan alkuperäisestä
  lähteestä ja tarkistetaan tiivisteellä.

---

## 9. Toteutuksen vaiheet

1. **Perusta**: laitteiston hankinta, Ventoy ja osiointi, `stick.csv` + `Build-Stick.ps1`, `Docs\Playbooks.md`, `Start.cmd` + `Start.ps1` (skriptit tehty).
2. **Vastaanotto ja diagnostiikka**: `Intake-Report` (tehty), `Disk-Health`, `Export-Logs`.
3. **Korjaus ja varmuuskopio**: `Repair-System`, resetointiskriptit, `Backup-/Restore-UserData`, `Malware-Sweep`.
4. **Live-puoli**: oma WinPE (`Build-WinPE`), WinPE-valikko, Linux-skriptit (`Backup-Offline`, `Image-Disk`, `Wipe-Disk` + todistus).
5. **Asennus ja luovutus**: `autounattend`-variantit, `PostInstall`, `Debloat`, `Handoff-Checklist`.
6. **Ylläpito**: `Gen-VentoyJson`, `Purge-Cases`.
7. **Myöhemmin**: PXE-käynnistys huollon verkkoon (iPXE + sama sisältö), tapausten raportointi keskitettyyn järjestelmään.

**Testaus:** skriptit testataan oikealla testikoneella ennen kuin niitä käytetään korjattavissa koneissa.
