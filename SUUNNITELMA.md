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
| 1 | `VENTOY` | exFAT | 600 GB | ISO-, WIM-, VHD(X)- ja IMG-kuvat sekä `ventoy/ventoy.json` |
| 2 | `VTOYEFI` | FAT16 | 32 MB | Ventoyn käynnistyslatain (luodaan automaattisesti) |
| 3 | `TOOLS` | NTFS | 250 GB | Portable-ohjelmat, skriptit, ajurit, offline-asennuspaketit ja dokumentaatio |
| 4 | `CASES` | NTFS + BitLocker *tai* VeraCrypt | 1 TB | Asiakkaiden varmuuskopiot ja raportit, **aina salattuna** |
| 5 | `LINUX` | ext4 | 100 GB | Pysyvä tallennus (persistence) Linux-liveille, `ddrescue`-kuvat ja -lokit |

Secure Boot: Ventoyn `ENROLL_THIS_KEY_IN_MOKMANAGER.cer` rekisteröidään koneisiin
tarvittaessa. Muuten Secure Boot otetaan väliaikaisesti pois päältä ja
**laitetaan takaisin päälle** ennen luovutusta (kirjataan tarkistuslistaan).

---

## 3. Live- ja käynnistyskuvat (`VENTOY`-osio)

### 3.1 Windows-pohjaiset (WinPE)
- **Oma WinPE** (Windows ADK + WinPE add-on). Mukana tallennusohjainten ajurit
  (Intel RST/VMD, AMD RAID, NVMe), verkkokorttien ajurit, PowerShell,
  .NET ja oma käynnistysvalikko. Tämä on **pääasiallinen työkalu**, koska sen
  sisällön tietää tarkalleen.
- **Hiren's BootCD PE**: ilmainen ja laillinen WinPE, jossa on valmiit työkalut.
- **Windows 11 -asennusmedia** (virallinen ISO, uusin versio) + `autounattend.xml`-variantit
  (paikallinen tili, ei bloatia, ohitetaan TPM-/verkkovaatimus vain asiakkaan luvalla).
- **Windows 10 22H2 -asennusmedia** (vanhoille koneille niin kauan kuin tarvitaan).
- **Windows 11 VHDX** (Ventoyn `vhdboot`-lisäosa): täysi Windows tikulta, kun WinPE ei riitä
  (esim. ohjelmat, jotka vaativat täyden Windowsin).

### 3.2 Linux-pohjaiset
- **SystemRescue**: yleistyökalu (`ddrescue`, `smartctl`, `nvme-cli`, `testdisk`, `chntpw`, `rsync`, GParted).
- **Ubuntu LTS / Fedora Workstation Live**: graafinen ympäristö, laitteistotestit, asiakkaalle näytettävät demot.
- **GParted Live**: osiointi.
- **Clonezilla Live** ja **Rescuezilla**: levykuvat ja kloonaus.
- **ShredOS (nwipe)**: sertifioitava levyjen tyhjennys ja raportti.
- **Memtest86+** (avoin) ja **PassMark MemTest86** (UEFI, ilmaisversio).
- **ESET SysRescue Live**: virustorjunta koneesta, jonka Windows ei käynnisty.
- **Kaspersky Rescue Disk**: toinen mielipide, jos saatavilla ja yrityksen linjaus sallii.
- **Ultimate Boot CD**: vanhat BIOS-ajan levytestit (MHDD, HDAT2, valmistajien työkalut).
- **ChromeOS Flex**: vanhan koneen uusiokäyttö asiakkaan pyynnöstä.
- **netboot.xyz**: kaikki muu verkon kautta.
- *(valinnainen)* **Kali Linux**: verkkovianmääritys. Vain omissa ja asiakkaan luvalla tutkittavissa verkoissa.

### 3.3 Valmistajien diagnostiikka
- Lenovo Diagnostics bootable, Dell ePSA/SupportAssist -ohjeet, HP PC Hardware Diagnostics UEFI
  (kopioidaan ESP:hen tarvittaessa), Seagate SeaTools Bootable, WD Dashboard -ohjeet.

---

## 4. Portable-ohjelmat (`TOOLS\Portable`)

Ohjelmat järjestetään kansioihin luokittain. Jokaiselle kirjataan `manifest.json`-tiedostoon
versio, lähde-URL ja SHA256-tiiviste (ks. luku 8).

### 4.1 Järjestelmätiedot
HWiNFO, CPU-Z, GPU-Z, HWMonitor, Core Temp, Speccy,
Sysinternals Suite (Autoruns, Process Explorer, Process Monitor, TCPView, RAMMap, Sigcheck),
NirSoft-työkalut (BlueScreenView, BatteryInfoView, ProduKey, USBDeview, DevManView, WifiInfoView,
LastActivityView, FullEventLogView), WhoCrashed, LatencyMon.

### 4.2 Levyt ja tallennus
CrystalDiskInfo, CrystalDiskMark, Hard Disk Sentinel, Victoria, HD Tune, smartmontools (`smartctl`),
WizTree, TreeSize Free, DiskGenius, MiniTool Partition Wizard / AOMEI Partition Assistant,
Hasleo Backup Suite Free, HDD Raw Copy Tool, FastCopy, Rufus, Ventoy2Disk.

### 4.3 Tietojen palautus
TestDisk/PhotoRec, DMDE (ilmaisversio), Recuva, ShadowExplorer.

### 4.4 Rasitustestit
OCCT, Prime95, y-cruncher, FurMark, Cinebench, TestMem5 + asetusprofiilit, HeavyLoad,
Keyboard Test Utility, InjuredPixels (kuolleet pikselit), webkameran ja mikrofonin testisivut offline-HTML:nä.

### 4.5 Haittaohjelmat
Malwarebytes ADWCleaner, Malwarebytes Free, KVRT, ESET Online Scanner,
Emsisoft Emergency Kit, HitmanPro, Microsoft Safety Scanner (`msert`), RKill, Farbar Recovery Scan Tool (FRST),
RogueKiller, Autoruns.

### 4.6 Windowsin korjaus ja ylläpito
Tweaking.com Windows Repair, Dism++, Display Driver Uninstaller (DDU), NVCleanstall,
Revo Uninstaller / Bulk Crap Uninstaller, O&O ShutUp10++, Snappy Driver Installer Origin
(+ offline-ajuripaketit), Windows Update MiniTool, ShowKeyPlus (lisenssiavaimen tarkistus).

### 4.7 Verkko
Advanced IP Scanner, Angry IP Scanner, Wireshark Portable, Nmap/Zenmap, PuTTY, WinSCP, iperf3,
NetSetMan, WinMTR, TCPing.

### 4.8 Etätuki
RustDesk, TeamViewer QuickSupport, AnyDesk.

### 4.9 Yleistyökalut
7-Zip, Notepad++, Everything, Firefox Portable, SumatraPDF, VLC, ShareX/Greenshot, HashMyFiles,
KeePassXC (omat salasanat ja tuoteavaimet salattuna), Bulk Rename Utility,
PortableApps.com Platform -käynnistin.

---

## 5. Skriptit (`TOOLS\Scripts`) – projektin varsinainen ydin

Kaikki skriptit kirjoittavat lokin ja raportin kansioon `CASES:\<tikettinumero>\`.
Yhteinen kirjasto löytää tikun osiot **levyn nimen (labelin)** perusteella, ei kirjaintunnuksen perusteella.

### 5.1 Käynnistys ja valikko
| Skripti | Tehtävä |
|---|---|
| `Start.cmd` / `Start.ps1` | Pääsyvalikko (TUI): kysyy tikettinumeron, luo tapauskansion ja näyttää työkalut luokittain |
| `winpe\startnet.cmd` | WinPE:n käynnistys: verkko päälle, osiot labelin perusteella, valikko |
| `lib\Common.psm1` | Yhteiset funktiot: osioiden etsintä, lokitus, järjestelmänvalvojan tarkistus, raporttipohja |

### 5.2 Vastaanotto ja inventaario
| Skripti | Tehtävä |
|---|---|
| `Intake-Report.ps1` | Valmistaja, malli, sarjanumero, BIOS, CPU, RAM, levyt ja SMART, akku, OS-versio, aktivointi, **BitLockerin tila**, laitteet, joissa on virhe, käynnistysaika ja asennetut ohjelmat. Tulokset HTML:nä ja JSON:na. |
| `BitLocker-Check.ps1` | Selvittää salauksen ja palautusavaimen **ennen mitään muutoksia**. Pysäyttää työn, jos avain puuttuu. |
| `Export-Logs.ps1` | Tapahtumalokit (System/Application, 30 vrk), Reliability History, minidumpit, `setupapi`, WER |
| `Battery-Report.ps1` | `powercfg /batteryreport` ja kulumaprosentti |

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
| `Update-Tools.ps1` | Lataa uusimmat versiot `manifest.json`-tiedoston lähteistä, tarkistaa allekirjoituksen tai tiivisteen ja päivittää manifestin |
| `Update-ISOs.ps1` | Tarkistaa ISO-kuvien versiot ja tiivisteet |
| `Verify-Integrity.ps1` | Vertaa TOOLS- ja VENTOY-osioiden tiivisteitä tunnettuun hyvään tilaan. **Ajetaan jokaisen saastuneen koneen jälkeen.** |
| `Build-WinPE.ps1` | Rakentaa oman WinPE:n ADK:lla, lisää ajurit, PowerShellin ja valikon |
| `Gen-VentoyJson.ps1` | Tuottaa `ventoy.json`-tiedoston: valikkoaliakset, luokat, teema ja autoinstall-liitokset |
| `Purge-Cases.ps1` | Poistaa tapaukset, jotka ovat vanhempia kuin säilytysaika (esim. 30 vrk luovutuksesta), ja kirjaa poistot |

---

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
│   ├── 1-WinPE\           (oma WinPE, Hiren's)
│   ├── 2-Windows\         (Win11, Win10)
│   ├── 3-Linux\           (SystemRescue, Ubuntu, Fedora, GParted)
│   ├── 4-Backup\          (Clonezilla, Rescuezilla)
│   ├── 5-Diag\            (Memtest86+, MemTest86, UBCD, valmistajat)
│   ├── 6-Antivirus\       (ESET, Kaspersky)
│   └── 7-Wipe\            (ShredOS)
├── VHD\                   (Windows 11 To Go -tyyppinen VHDX)
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
├── Docs\
├── Templates\
├── manifest.json
└── SHA256SUMS

CASES:\  (salattu)
└── <VVVV-KK-PP>_<tiketti>\
    ├── intake\   logs\   backup\   reports\
    └── case.json
```

Tämä Git-repositorio sisältää `TOOLS`-osion **skriptit, konfiguraatiot, dokumentaation,
pohjat ja manifestin**. Binäärit ja ISO-kuvat eivät kuulu repositorioon, vaan
`Update-Tools.ps1` ja `Update-ISOs.ps1` hakevat ne.

---

## 8. Tietoturva ja tietosuoja

- **Tikku itse on riski.** Se kytketään saastuneisiin koneisiin. Siksi:
  automaattinen käynnistys on pois päältä, `Verify-Integrity.ps1` ajetaan jokaisen
  haittaohjelmatapauksen jälkeen, kultainen kopio pidetään erillään, ja vakavat
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

1. **Perusta**: laitteiston hankinta, Ventoy ja osiointi, hakemistorakenne, `manifest.json`-skeema, `lib\Common.psm1`, `Start.ps1`-valikko.
2. **Vastaanotto ja diagnostiikka**: `Intake-Report`, `BitLocker-Check`, `Disk-Health`, `Export-Logs`, `Battery-Report` ja HTML-raporttipohja.
3. **Korjaus ja varmuuskopio**: `Repair-System`, resetointiskriptit, `Backup-/Restore-UserData`, `Malware-Sweep`.
4. **Live-puoli**: oma WinPE (`Build-WinPE`), WinPE-valikko, Linux-skriptit (`Backup-Offline`, `Image-Disk`, `Wipe-Disk` + todistus).
5. **Asennus ja luovutus**: `autounattend`-variantit, `PostInstall`, `Debloat`, `Handoff-Checklist`.
6. **Ylläpito**: `Update-Tools`, `Update-ISOs`, `Verify-Integrity`, `Gen-VentoyJson`, `Purge-Cases`.
7. **Myöhemmin**: PXE-käynnistys huollon verkkoon (iPXE + sama sisältö), tapausten raportointi keskitettyyn järjestelmään.
