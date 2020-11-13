* Encoding: windows-1252.

* map met alle kadasterdata.
DEFINE datamap () 'C:\temp\kadaster\' !ENDDEFINE.
* dit gaat ervan uit dat je een map "upload" hebt in deze map.

* map met alle data die van Github komt.
DEFINE github () 'C:\github\' !ENDDEFINE.

* jaartal waarvoor we werken.
DEFINE datajaar () '2019' !ENDDEFINE.



GET
  FILE=datamap+ 'werkbestanden\eigendom_' + datajaar + '.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

* geef mooi aan vanaf welk punt je dingen zelf hebt gedaan.
compute AFGELEIDE_VARIABELEN=$sysmis.

* LUIK 1: zorg dat je kan koppelen aan statsec.
compute LUIK1=$sysmis.


variable labels huidig_bewoond "huishoudens gekoppeld aan deze eigendom".

* gewone gevallen.
* we werken steeds op basis van de recenste tabel!.
* 2019: gebiedsnveau is al NIEUWE niscode en NIEUWE statsec.
GET
  FILE=datamap+ 'werkbestanden\koppeling_meest_recent.sav'.
DATASET NAME koppeling WINDOW=FRONT.
*DATASET ACTIVATE koppeling.
DATASET DECLARE statsec.
AGGREGATE
  /OUTFILE='statsec'
  /BREAK=capakey stat_sector
  /N_BREAK=N.
dataset activate statsec.
freq n_break.
delete variables n_break.

dataset activate eigendommen.
sort cases capakey (a).
dataset close koppeling.

DATASET ACTIVATE eigendommen.
MATCH FILES /FILE=*
  /TABLE='statsec'
  /BY capakey.
EXECUTE.
dataset close statsec.

* einde gewone gevallen.

* afhandelen onbekende statsec.
** in enkele honderden gevallen gaat iets mis. Oorzaak: allicht iets mis met de geometrie, of ze ontbreken volledig in de geometrie, of er is iets mis met de capakey.
** maar van die percelen weten we wel in welke gemeente ze liggen. Immers is er een 1-op-1 relatie tussen de eerste vijf tekens van de capakey en de gemeente.
** de kopeltabel werd reeds in een eerder script aangemaakt.
STRING  capa5 (A5).
COMPUTE capa5=capakey.
EXECUTE.

GET
  FILE=datamap+ 'werkbestanden\x_capa5_niscode.sav'.
DATASET NAME tussentabel WINDOW=FRONT.
DATASET ACTIVATE eigendommen.
sort cases capa5 (a).
MATCH FILES /FILE=*
  /TABLE='tussentabel'
  /BY capa5.
EXECUTE.
dataset close tussentabel.

alter type niscode (a5).
if stat_sector="" stat_sector=concat(niscode,"ZZZZ").


* EINDE LUIK 1.


* LUIK 2: voorbereiding indicatoren.
compute LUIK2=$sysmis.


* maak een dummy "bewoond of niet" op basis van  huidig_bewoond.
recode huidig_bewoond (1 thru highest=1) (else=0) into bewoond.
value labels bewoond
0 "geen huidige bewoning"
1 "wel huidige bewoning".


* woonfunctie
** recode op aard op basis van ons wordbestand.
** in de toekomst is dit gewoon een dummy aangeleverd door Cevi.
*** opmerking: privat.delen# komt niet voor in de data.
recode aard
('APPARTEMENT #'=1)
('BUILDING'=1)
('D.AP.GEB.#W'=1)
('HANDELSHUIS'=1)
('HOEVE'=1)
('HUIS'=1)
('HUIS#'=1)
('KAMER #   '=1)
('PRIVAT. DELEN'=1)
('KASTEEL'=1)
('KLOOSTER'=1)
('PRIVAT. DELEN#'=1)
('NOODWONING'=1)
('PASTORIE'=1)
('RUSTHUIS'=1)
('STUDIO #'=1)
('WEESHUIS'=1)
('WELZIJNSGEBOUW'=1)
(else=0) into woonfunctie.
value labels woonfunctie
0 "geen woonfunctie"
1 "wel een woonfunctie".


* woongelegenheden.
** indien woonfunctie=1
*** grootste van huishoudens en wooneenheden.
** indien woonfunctie=0 
*** tel aantal huishoudens

compute woongelegenheden=$sysmis.
if woonfunctie=1 woongelegenheden=max(wooneenheden,huidig_bewoond).
if woonfunctie=0  woongelegenheden=huidig_bewoond.

* woonaanbod = woongelegenheden waarbij woonfunctie=1.
if woonfunctie=1 wgl_woonfunctie=woongelegenheden.


* type woongelegenheden
** woonaanbodsindeling (dus woonfunctie=1, maar dit hoeven we niet te expliciteren aangezien alle gebruikte aarden woonfunctie hebben)
** teller=woongelegenheden.
recode aard
('APPARTEMENT #'=2)
('BUILDING'=2)
('D.AP.GEB.#W'=2)
('HANDELSHUIS'=1)
('HOEVE'=1)
('HUIS'=1)
('HUIS#'=1)
('KAMER #   '=2)
('KASTEEL'=1)
('KLOOSTER'=3)
('NOODWONING'=1)
('PASTORIE'=1)
('PRIVAT. DELEN'=2)
('RUSTHUIS'=3)
('STUDIO #'=2)
('WEESHUIS'=3)
('WELZIJNSGEBOUW'=3) into type_woonaanbod.
value labels type_woonaanbod
1 "individuele woning"
2 "appartement"
3 "collectieve woning".


* meergezinspercelen: dit minst slechte manier om meergezinswoningen te benaderen.
** indeling van de woonvoorraad (oftewel alle woongelegenheden).
* we kennen de nodige tussentijdse info toe aan alle perceeldelen (opgelet, deze mag je niet nog eens optellen!).
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /woongelegenheden_perceel_tot=SUM(woongelegenheden)
  /aantal_eigendommen=N.

* onderstaande variabele is enkel zinvol op niveau van een perceel, en dat in een dataset op niveau eigendommen. Let dus op bij interpretatie.
if woongelegenheden_perceel_tot =1 eengezin_meergezin = 1.
if woongelegenheden_perceel_tot >1 eengezin_meergezin = 2.
value labels eengezin_meergezin
1 "eigendom op perceel met 1 woongelegenheid"
2 "eigendom op perceel met meerdere woongelegenheden".


* huurder/eigenaar
** tellling van huishoudens die we hebben kunnen koppelen

* classificering van eigendommen naar eigenaars volgens type.
* A=ander recht; E=gewone eigenaar; G=vruchtgebruik.
recode bewoner_code ('A'=1) ('E'=1) ('G' = 1) ('H' = 2) (else=0) into eigenaar_huurder.
if huidig_bewoond=0 eigenaar_huurder = 3.
value labels eigenaar_huurder
0 'onbekend'
1 'eigenaar in brede zin'
2 'huurder'
3 'onbewoond'.
freq eigenaar_huurder.
* er zouden enkel onbekende mogen overblijven indien het gata om "valse records" die we hebben toegevoegd om zeker een rij te hebben voor elke statsec (in de praktijk: 10240 rijen).

* indicatoren.
* huishoudens in verhuurde wooneenheden.
** omvat alle huishoudens in verhuurde eigendommen.
if eigenaar_huurder = 2 hurende_huishoudens=huidig_bewoond.
** MAAR OOK extra huishoudens in eigendommen met inwonende eigenaars.
if eigenaar_huurder = 1 & huidig_bewoond > 1 hurende_huishoudens = huidig_bewoond - 1.

* huishoudens eigenaarswoningen (de fout is kleiner als er slechts één inwonend gezin is op een eigendom).
if eigenaar_huurder = 1 inwonend_eigenaarsgezin=1.
EXECUTE.
** einde huurder/eigenaar


****** start bouwjaar.
*** data-cleaning.
compute bouwjaar_clean=bouwjaar.
compute laatste_wijziging_clean=laatste_wijziging.
* gebouwen die in de toekomst (of in het huidige jaar) werden gebouwd beschouwen we als "bouwjaar onbekend".
if bouwjaar>=jaartal bouwjaar_clean = -1.
* gebouwen die werden gerenoveerd in de toekomst  (of in het huidige jaar) werden gebouwd beschouwen we als "wijziging onbekend".
if laatste_wijziging>=jaartal laatste_wijziging_clean = -1.
* gebouwen die pas werden gebouwd nadat ze werden gerenoveerd beschouwen we als fout wijzigingsjaar .
if ( laatste_wijziging<bouwjaar & bouwjaar>=0 & laatste_wijziging>0 ) laatste_wijziging_clean = -1.

* als het bouwjaar groter is dan 5 en kleiner dan 1931, dan is het fout.
if bouwjaar>5 & bouwjaar<1931 bouwjaar_clean=-1.

* als het wijzigingsjaar kleiner is dan 1983, dan is het wellicht een raar geval en nemen we het niet mee.
if laatste_wijziging>0 & laatste_wijziging<1983 laatste_wijziging_clean=-1.

missing values bouwjaar_clean laatste_wijziging_clean (-1).


* tussenstap/dummy code obv variabele 'bouwjaar' (naar gewenste categorieën).
* de categorie 'onbekend'  bevat alle missing values + wat we als onlogisch hebben gedefinieerd + de categorie '0000' (="verkoop op plan").
RECODE bouwjaar_clean 
(0=13)
(1=1) 
(2=1) 
(3=1) 
(4=2) 
(5=3) 
(1931 thru 1945=4) 
(1946 thru 1960=5) 
(1961 thru 1970=6) 
(1971 thru 1980=7) 
(1981 thru 1990=8) 
(1991 thru 2000=9) 
(2001 thru 2010=10) 
(2011 thru 2020=11) 
(2021 thru 2030=12) 
(ELSE=13) INTO bouwjaar_cat.

* dummy bouwjaar enkel van de woongelegenheden.
* de categorie 'onbekend' (label value 12) bevat alle missing values + de categorie '0000' (="verkoop op plan") + elk jaartal vanaf 2019.
** deze code (value label) moet aangepast worden voor elke nieuwe dataset (laatste jaartal dat wordt meegenomen in de categorie 'na 2010').
compute bouwjaar_cat_wgl=$sysmis.
if woongelegenheden>=1 bouwjaar_cat_wgl=bouwjaar_cat.
value labels bouwjaar_cat bouwjaar_cat_wgl
1 "voor 1900"
2 "1900-1918"
3 "1919-1930"
4 "1931-1945"
5 "1946-1960"
6 "1961-1970"
7 "1971-1980"
8 "1981-1990"
9 "1991-2000"
10 "2001-2010"
11 "2011-2020"
12 '2021-2030'
13 "onbekend".


*tussenstap/dummy 'laatste wijzigingen' naar gewenste categorieën (met zelfde label values als bouwjaar_cat).
* de categorie 'onbekend' bevat alle missing values + alle jaartallen tem 1982 + elk jaartal "in de toekomst".
RECODE laatste_wijziging_clean 
(1983 thru 1990=8) 
(1991 thru 2000=9) 
(2001 thru 2010=10) 
(2011 thru 2020=11) 
(2021 thru 2030=12) 
(ELSE=13) INTO laatste_wijziging_cat.


* dummy laatste wijziging enkel van de woongelegenheden.
* de categorie 'onbekend' (label value 12) bevat alle missing values + alle jaartallen tem 1982 + elk jaartal in de toekomst.
compute laatste_wijziging_cat_wgl=$sysmis.
if woongelegenheden>=1 laatste_wijziging_cat_wgl=laatste_wijziging_cat.
value labels laatste_wijziging_cat laatste_wijziging_cat_wgl
8 "1983-1990"
9 "1991-2000"
10 "2001-2010"
11 "2011-2020"
12 "2021-2030"
13 "onbekend".


* we maken een combinatie van bouwjaar en wijzigingsjaar om een indicatie te krijgen van de "recentheid" van het woonpatrimonium.
* voor gebouwen gebouwd VOOR 1983 zonder wijzigingsjaar geldt:
- gebouwd voor 1983 en geen gekende wijziging
- bij een gebouw van uit 1900 kunnen we *geen* onderscheid maken tussen: gebouwd en nooit aangepast; of gebouwd en wie weet aangepast voor 1983
- voorlopig doen we daarom enkel "alle woongelegenheden die sinds 1983 gewijzigd of gebouwd zijn".

compute recentste_jaar=max(bouwjaar_clean,laatste_wijziging_clean).

** einde bouwjaar.

* bouwvorm (zie afspraken 20201016).
if eengezin_meergezin=1 & soort_bebouwing="Open bebouwing" egw_open_bouwvorm = woongelegenheden.
if eengezin_meergezin=1 & soort_bebouwing="Halfopen bebouwing" egw_halfopen_bouwvorm = woongelegenheden.
if eengezin_meergezin=1 & soort_bebouwing="Gesloten bebouwing" egw_gesloten_bouwvorm = woongelegenheden.
if eengezin_meergezin=1 & soort_bebouwing~="Open bebouwing" & soort_bebouwing~="Halfopen bebouwing" & soort_bebouwing~="Gesloten bebouwing" 
egw_andere_bouwvorm = woongelegenheden.

variable labels egw_open_bouwvorm 'eengezinswoning in open bebouwing'.


EXECUTE.
* EINDE LUIK 2.

* LUIK3: toevoegen bewoning zonder link.
compute LUIK3=$sysmis.

PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + datajaar + '\KAD_' + datajaar + '_bewoning_zonder_link.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  niscode A5
  adrescode A12
  straatnaamcode F6.0
  huisbis A12
  aantal_gezinnen F2.0
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME bzl WINDOW=FRONT.

* komt zelfs in 2019 nog voor.
recode niscode ('12030'='12041')
('12034'='12041')
('44011'='44083')
('44049'='44083')
('44001'='44084')
('44029'='44084')
('44036'='44085')
('44072'='44085')
('44080'='44085')
('45017'='45068')
('45057'='45068')
('71047'='72042')
('72040'='72042')
('72025'='72043')
('72029'='72043').

string stat_sector (a9).
compute stat_sector = concat(niscode,"ZZZZ").
rename variables aantal_gezinnen = bewoning_zonder_link.
match files
/file=*
/keep=provincie
jaartal
niscode
bewoning_zonder_link
stat_sector.


DATASET ACTIVATE eigendommen.
ADD FILES /FILE=*
  /FILE='bzl'.
EXECUTE.
dataset close bzl.



SAVE OUTFILE= datamap +  'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sav'
  /COMPRESSED.

SAVE TRANSLATE OUTFILE=datamap + 'werkbestanden\eigendom_' + datajaar + '_basisafspraken.csv'
  /TYPE=CSV
  /ENCODING='Locale'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES
/replace.

SAVE TRANSLATE OUTFILE=datamap + 'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sas7bdat'
  /TYPE=SAS
  /VERSION=7
  /PLATFORM=WINDOWS
  /ENCODING='Locale'
  /MAP
  /REPLACE.
