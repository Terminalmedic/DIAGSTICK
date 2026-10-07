# Toimintaohjeet oireittain

Jokainen ohje alkaa samalla tavalla:

0. **BitLocker ensin.** Jos levy on salattu, etsi palautusavain ennen muutoksia
   (Microsoft-tili → https://account.microsoft.com/devices/recoverykey).
   Ilman avainta et tee mitään, mikä voi laukaista palautustilan
   (BIOS-päivitys, Secure Bootin muutos tai levyn siirto toiseen koneeseen).
1. **Tiedot talteen ennen korjausta**, jos niitä on ja levy on epäilyttävä.

Työkalut löytyvät tikulta: ISO-kuvat Ventoyn valikosta, ohjelmat kansiosta `TOOLS:\Portable\`.

---

## Kone ei käynnisty

1. Tuleeko kuvaa ja valmistajan logo?
   - **Ei mitään** (ei tuuletinta tai valoja) → virtalähde, laturi ja akku. Kokeile toista laturia; pöytäkoneessa käynnistä ilman lisäkortteja.
   - **Tuulettimet pyörivät, ei kuvaa** → RAM: jätä yksi kampa, vaihda paikkaa. Kokeile toista näyttöporttia (integroitu vs. erillinen näytönohjain).
   - **Logo näkyy** → jatka.
2. Näkyykö levy BIOSissa? **Ei** → levy tai liitäntä vikaantunut → *Levy hajoaa*.
3. Käynnistä **SystemRescue** → `smartctl -a /dev/nvme0n1` (tai `/dev/sda`). Huono SMART → *Levy hajoaa*.
4. Levy kunnossa → käynnistä **Hiren's PE** (tai Windows 11 -asennusmedia → Korjaa) → komentokehote:
   `bootrec /scanos`, `bcdboot C:\Windows`. Jos se ei auta: `sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows`.
5. Ei apua → tiedot talteen, Windowsin uudelleenasennus (*Siirto uuteen koneeseen / asennus*).

## Kone on hidas

1. **CrystalDiskInfo**: onko levy "Varoitus" tai HDD? HDD → suosittele SSD:tä, se on yleensä koko vika.
2. Tehtävienhallinta → mikä kuormittaa (CPU, levy, RAM)? RAM jatkuvasti yli 90 % → lisämuisti.
3. **Sysinternals Autoruns**: poista turhat käynnistyskohteet (ei Microsoftin tai ajurien omia).
4. **HWiNFO**: lämpötilat kuormassa. CPU yli 95 °C ja kellotaajuus putoaa → tuuletinten ja jäähdytyksen puhdistus, piitahna.
5. Haittaohjelmia epäillään → *Virus tai huijaus*.
6. Vasta lopuksi: `DISM /Online /Cleanup-Image /RestoreHealth` ja `sfc /scannow`.

## Sininen ruutu (BSOD) tai jäätyminen

1. Pysäytyskoodi ja ajurin nimi: Tapahtumienvalvonta → Järjestelmä (BugCheck, Kernel-Power 41) ja `C:\Windows\Minidump\`.
2. Sama ajuri toistuu → päivitä tai palauta se. Näytönohjainajuri → **DDU** vikasietotilassa ja puhdas asennus.
3. Vaihteleva koodi → laitteistovika:
   - **Memtest86+** vähintään yksi täysi kierros. Yksikin virhe → RAM vaihtoon.
   - **CrystalDiskInfo** / `smartctl`.
   - **OCCT**: CPU 10 min, sitten virtalähdetesti. Kaatuu → lämmöt (HWiNFO) tai virtalähde.
4. Jäätyy ilman ruutua → todennäköisemmin lämpö, virtalähde tai levy kuin ohjelmisto.

## Virus tai huijaus

1. **Huijauspuhelu tai etäyhteys?** Irrota verkko heti. Poista etätyökalut (AnyDesk, TeamViewer ym.) ja vaihda **toiselta laitteelta** pankin, sähköpostin ja Microsoft-tilin salasanat. Pankkiin yhteys saman tien.
2. Skannaa järjestyksessä: **KVRT** → **AdwCleaner** → **msert**.
3. **Autoruns**: oudot ajastetut tehtävät, palvelut ja selainlaajennukset.
4. Ei käynnisty tai skannerit eivät pysty toimimaan → **ESET SysRescue** -live.
5. Kiristyshaittaohjelma tai rootkit → tiedot talteen (vain dokumentit, ei ohjelmia), levyn tyhjennys ja puhdas asennus.
6. Jälkeenpäin: aja `Build-Stick.ps1 -Verify` **toisella, puhtaalla koneella**.

## Verkko tai Wi-Fi ei toimi

1. Toimiiko muilla laitteilla samassa verkossa? Ei → reititin, ei kone.
2. Laitehallinnassa verkkokortti ilman ajuria → **SDIO** tai valmistajan ajuri tikulta.
3. `ipconfig /all`: 169.254.x.x = ei DHCP:tä. `ping 1.1.1.1` toimii mutta nimi ei → DNS.
4. Nollaa verkkopino: `netsh winsock reset`, `netsh int ip reset`, `ipconfig /flushdns` ja uudelleenkäynnistys.
5. Wi-Fi-raportti: `netsh wlan show wlanreport`.

## Levy hajoaa, tiedot pelastettava

1. **Älä käynnistä Windowsia viallisella levyllä**, koska jokainen käynnistys kuluttaa levyä.
2. **SystemRescue** → levykuva ensin, vasta sitten tiedostot:
   `ddrescue -n /dev/sdX /mnt/linux/kuva.img kuva.map` ja sitten uusinta `ddrescue -r3 ...` samalla map-tiedostolla.
3. Kuvasta: mounttaa ja kopioi, tai **TestDisk/PhotoRec** / **DMDE**, jos osiot tai tiedostojärjestelmä ovat rikki.
4. Levy ei näy lainkaan tai naksuttaa → ohjelmisto ei auta, laboratorio.

## Salasana unohtunut / BitLocker kysyy avainta

- **Microsoft-tili**: nollaus osoitteessa https://account.live.com/password/reset toisella laitteella.
- **Paikallinen tili**: Windowsin palautuskysymykset tai nollauslevy. Viimeisenä keinona SystemRescue → `chntpw` (vain laitteen omistajan pyynnöstä, ja BitLockerin on oltava pois päältä tai avaimen tiedossa).
- **BitLocker kysyy palautusavainta**: katso kohta 0. Avainta ei voi ohittaa. Ilman sitä tiedot ovat menetetty, ja jäljelle jää vain puhdas asennus.

## Siirto uuteen koneeseen / asennus

1. Vanhasta koneesta: dokumentit, työpöytä, kuvat, selainprofiilit, Outlookin PST, Wi-Fi-profiilit (`netsh wlan export profile key=clear folder=...`), asennettujen ohjelmien lista (`winget export`).
2. Asennus: **Windows 11** -ISO Ventoysta. Jos asennus ei näe levyä → Intel RST/VMD -ajuri tikulta.
3. Asennuksen jälkeen: Windows Update, ajurit (valmistajan työkalu tai **SDIO**), `winget import`, tiedot takaisin.
4. Vanhan koneen levy tyhjennetään luovutettaessa → **ShredOS**.

## Ennen luovutusta

- Secure Boot päällä, BitLocker/laitesalaus päällä ja palautusavain tallessa, Windows aktivoitu, päivitykset ajettu.
- Väliaikaiset tunnukset poistettu, huoltotyökalut pois koneelta.
