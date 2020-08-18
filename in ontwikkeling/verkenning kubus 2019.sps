* Encoding: windows-1252.
* OPGELET: er is een harde compute period=2019 nodig vlak voor het aggregeren naar swing.

GET
  FILE='C:\temp\kadaster\werkbestanden\eigendom_2019.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

* geef mooi aan vanaf welk punt je dingen zelf hebt gedaan.
compute AFGELEIDE_VARIABELEN=$sysmis.

* LUIK 1: zorg dat je kan koppelen aan statsec.
compute LUIK1=$sysmis.


* gewone gevallen.
* we werken steeds op basis van de recenste tabel!.
* 2019: gebiedsnveau is al NIEUWE niscode en NIEUWE statsec.
GET
  FILE='C:\temp\kadaster\werkbestanden\koppeling_2019.sav'.
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
  FILE='C:\temp\kadaster\werkbestanden\x_capa5_niscode.sav'.
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

* in 2019 duiken opeens een heel aantal "appartementen" op die duidelijk geen woning zijn.
* het is niet helemaal duidelijk wat hier dan wel de functie van is, maar we nemen ze alvast niet mee als dingen met een "woonfunctie".
* in 2018 is dit nog zeer zeldzaam, maar we nemen het toch al mee omwille van de consistentie.
if aard = "APPARTEMENT #" & subtype_woning="" woonfunctie=0.


* woongelegenheden.
** indien woonfunctie=1
*** grootste van huishoudens en wooneenheden.
*** woonfunctie=1 & wooneenheden=0 >>> woongelegenheid=1 (indien we niet al een grotere waarde hebben ingevuld!).
** indien woonfunctie=0 
*** tel aantal huishoudens




compute woongelegenheden=$sysmis.
if woonfunctie=1 woongelegenheden=max(wooneenheden,huidig_bewoond).
if woonfunctie=1 & (missing(wooneenheden) | wooneenheden=0) & (missing(huidig_bewoond) | huidig_bewoond=0) woongelegenheden=1.
if (missing(woongelegenheden) | woongelegenheden=0) & woonfunctie=1 woongelegenheden=1.
if woonfunctie=0  woongelegenheden=huidig_bewoond.

* woonvoorraad = woongelegenheden.
compute v2210_woonvoorraad=woongelegenheden.

* woonaanbod = woongelegenheden waarbij woonfunctie=1.
if woonfunctie=1 v2210_woonaanbod=woongelegenheden.


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
('WELZIJNSGEBOUW'=3) into v2210_type_woonaanbod.
value labels v2210_type_woonaanbod
1 "individuele woning"
2 "appartement"
3 "collectieve woning".

if v2210_type_woonaanbod=1 v2210_wa_indiv=woongelegenheden.
if v2210_type_woonaanbod=2 v2210_wa_app=woongelegenheden.
if v2210_type_woonaanbod=3 v2210_wa_coll=woongelegenheden.


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

* indicatoren eengezins/meergezinswoningen. Dit is een indeling van de woonvoorraad (wv).
* al deze indicatoren kunnen eenvoudig opgeteld worden.

if eengezin_meergezin=1 v2210_wv_eengezinswoningen=woongelegenheden.
if eengezin_meergezin=2 v2210_wv_meergezinswoningen=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot <=5 v2210_wv_mg_2_5=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot > 5 & woongelegenheden_perceel_tot <=10 v2210_wv_mg_6_10=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot >10 v2210_wv_mg_11p=woongelegenheden.



** tellling van huishoudens die we hebben kunnen koppelen
* strikt gezien niet nodig: teller aantal teruggevonden huishoudens.
compute v2210_huishoudens=huidig_bewoond.

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


* indicatoren.
* huishoudens in verhuurde wooneenheden.
** omvat alle huishoudens in verhuurde eigendommen.
if eigenaar_huurder = 2 v2210_huurders=huidig_bewoond.
** MAAR OOK extra huishoudens in eigendommen met inwonende eigenaars.
if eigenaar_huurder = 1 & huidig_bewoond > 1 v2210_huurders = huidig_bewoond - 1.

* huishoudens eigenaarswoningen (de fout is kleiner als er slechts één inwonend gezin is op een eigendom).
if eigenaar_huurder = 1 v2210_inwonend_eigenaarsgezin=1.
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

* dummy bouwjaar enkel van de woongelegenheden (obv variabele v2210_woonvoorraad).
* de categorie 'onbekend' (label value 12) bevat alle missing values + de categorie '0000' (="verkoop op plan") + elk jaartal vanaf 2019.
** deze code (value label) moet aangepast worden voor elke nieuwe dataset (laatste jaartal dat wordt meegenomen in de categorie 'na 2010').
compute bouwjaar_cat_wgl=$sysmis.
if v2210_woonvoorraad>=1 bouwjaar_cat_wgl=bouwjaar_cat.
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

* indicatoren bouwjaar (enkel bij woongelegenheden, obv woonvoorraad).
* al deze indicatoren kunnen eenvoudig opgeteld worden.
if bouwjaar_cat_wgl=1 v2210_wv_bj_voor1900=woongelegenheden.
if bouwjaar_cat_wgl=2 v2210_wv_bj_1900_1918=woongelegenheden.
if bouwjaar_cat_wgl=3 v2210_wv_bj_1919_1930=woongelegenheden.
if bouwjaar_cat_wgl=4 v2210_wv_bj_1931_1945=woongelegenheden.
if bouwjaar_cat_wgl=5 v2210_wv_bj_1946_1960=woongelegenheden.
if bouwjaar_cat_wgl=6 v2210_wv_bj_1961_1970=woongelegenheden.
if bouwjaar_cat_wgl=7 v2210_wv_bj_1971_1980=woongelegenheden.
if bouwjaar_cat_wgl=8 v2210_wv_bj_1981_1990=woongelegenheden.
if bouwjaar_cat_wgl=9 v2210_wv_bj_1991_2000=woongelegenheden.
if bouwjaar_cat_wgl=10 v2210_wv_bj_2001_2010=woongelegenheden.
if bouwjaar_cat_wgl=11 v2210_wv_bj_2011_2020=woongelegenheden.
if bouwjaar_cat_wgl=13 v2210_wv_bj_onbekend=woongelegenheden. 

*tussenstap/dummy 'laatste wijzigingen' naar gewenste categorieën (met zelfde label values als bouwjaar_cat).
* de categorie 'onbekend' bevat alle missing values + alle jaartallen tem 1982 + elk jaartal "in de toekomst".
RECODE laatste_wijziging_clean 
(1983 thru 1990=8) 
(1991 thru 2000=9) 
(2001 thru 2010=10) 
(2011 thru 2020=11) 
(2021 thru 2030=12) 
(ELSE=13) INTO laatste_wijziging_cat.


* dummy laatste wijziging enkel van de woongelegenheden (obv variabele v2210_woonvoorraad).
* de categorie 'onbekend' (label value 12) bevat alle missing values + alle jaartallen tem 1982 + elk jaartal in de toekomst.
compute laatste_wijziging_cat_wgl=$sysmis.
if v2210_woonvoorraad>=1 laatste_wijziging_cat_wgl=laatste_wijziging_cat.
value labels laatste_wijziging_cat laatste_wijziging_cat_wgl
8 "1983-1990"
9 "1991-2000"
10 "2001-2010"
11 "2011-2020"
12 "2021-2030"
13 "onbekend".

* indicatoren laatste wijziging (enkel bij woongelegenheden, obv woonvoorraad).
* al deze indicatoren kunnen eenvoudig opgeteld worden.
if laatste_wijziging_cat_wgl=8 v2210_wv_lw_1983_1990=woongelegenheden.
if laatste_wijziging_cat_wgl=9 v2210_wv_lw_1991_2000=woongelegenheden.
if laatste_wijziging_cat_wgl=10 v2210_wv_lw_2001_2010=woongelegenheden.
if laatste_wijziging_cat_wgl=11 v2210_wv_lw_2011_2020=woongelegenheden.
if laatste_wijziging_cat_wgl=13 v2210_wv_lw_onbekend=woongelegenheden.


* we maken een combinatie van bouwjaar en wijzigingsjaar om een indicatie te krijgen van de "recentheid" van het woonpatrimonium.
* voor gebouwen gebouwd VOOR 1983 zonder wijzigingsjaar geldt:
- gebouwd voor 1983 en geen gekende wijziging
- bij een gebouw van uit 1900 kunnen we *geen* onderscheid maken tussen: gebouwd en nooit aangepast; of gebouwd en wie weet aangepast voor 1983
- voorlopig doen we daarom enkel "alle woongelegenheden die sinds 1983 gewijzigd of gebouwd zijn".

compute recentste_jaar=max(bouwjaar_clean,laatste_wijziging_clean).
if recentste_jaar>=1983 & recentste_jaar <= 1990 v2210_wgl_lwbj_1983_1990=woongelegenheden.
if recentste_jaar>=1991 & recentste_jaar <= 2000 v2210_wgl_lwbj_1991_2000=woongelegenheden.
if recentste_jaar>=2001 & recentste_jaar <= 2010 v2210_wgl_lwbj_2001_2010=woongelegenheden.
if recentste_jaar>=2011 & recentste_jaar <= 2020 v2210_wgl_lwbj_2011_2020=woongelegenheden.
*if recentste_jaar>=2021 & recentste_jaar <= 1990 v2210_wgl_lwbj_2021_2030=woongelegenheden.
if recentste_jaar>=1983 v2210_wgl_lwbj_1983p=woongelegenheden.


EXECUTE.
** einde bouwjaar.


* EINDE LUIK 2.

* LUIK3: toevoegen bewoning zonder link.
compute LUIK3=$sysmis.

PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE="C:\temp\kadaster\2019\KAD_2019_bewoning_zonder_link.txt"
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

compute v2210_hh_onbekend = bewoning_zonder_link.






* LUIK 4: aggregatie naar Swing.
compute LUIK4=$sysmis.
* platte onderwerpen.


* we werken met WOONGELEGENHEDEN!

* deze kunnen zonder meer overgenomen worden in een kubus.
rename variables woonfunctie=v2210_woonfunctie.
rename variables bouwjaar_cat=v2210_bouwjaar_cat.
rename variables laatste_wijziging_cat=v2210_laatste_wijziging_cat.
rename variables eengezin_meergezin=v2210_eengezin_meergezin.

* losvaste afspraak: open/gesloten/appartement/andere gaat over "hoe iets gebouwd is", niet over effectief gebruik.
compute v2210_bouwvorm=0.
if v2210_type_woonaanbod=1 & soort_bebouwing="Open bebouwing" v2210_bouwvorm = 1.
if v2210_type_woonaanbod=1 & soort_bebouwing="Halfopen bebouwing" v2210_bouwvorm = 2.
if v2210_type_woonaanbod=1 & soort_bebouwing="Gesloten bebouwing" v2210_bouwvorm = 3.
if v2210_type_woonaanbod=2 v2210_bouwvorm = 4.
if v2210_type_woonaanbod=3  v2210_bouwvorm = 5.


* VERWIJDER WAT NIET NODIG IS.
* verwijder bewoning zonder link eerst.
* hou enkel woongelegenheden>0 over.
DATASET ACTIVATE eigendommen.
DATASET COPY  subset.
DATASET ACTIVATE  subset.
FILTER OFF.
USE ALL.
SELECT IF (woongelegenheden>0 & missing(bewoning_zonder_link)).
EXECUTE.

match files
/file=*
/keep=jaartal
capakey
eigendom_id
wooneenheden
huidig_bewoond
woongelegenheden
geoitem
v2210_huishoudens
v2210_huurders
v2210_inwonend_eigenaarsgezin eigenaar_huurder 
v2210_woonfunctie v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_bouwvorm v2210_eengezin_meergezin.


frequencies  v2210_woonfunctie eigenaar_huurder v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_bouwvorm v2210_eengezin_meergezin.

* de-aggregatie nodig vooraleer te aggregeren: eigenaar/huurder gaat over een eigendom, maar we willen uitspraken doen over woongelegenheden.

* we hebben al een teller met huurders en eigenaars, maar we hebben ook de "niet bewoonde" nodig om tot de woongelegenheden te komen.
* eens we die drie teleenheden hebben, dan kunnen we ze "onder elkaar" plakken in een nieuw bestand.
* om te kunnen rekenen, moeten de missings eerst weggewerkt worden.
recode v2210_huurders
v2210_huishoudens
v2210_inwonend_eigenaarsgezin (missing=0).
* vervolgens zonder we de niet bewoonde af.
compute tussenvar_nietbewoond=woongelegenheden-v2210_huurders-v2210_inwonend_eigenaarsgezin.

* vervolgens maken we een bestand waarin we respectievelijk enkel de onbewoonde, de huurders en de eigenaars in onze uiteindelijke teleenheid steken. 

DATASET ACTIVATE subset.
DATASET COPY  deaggregatie.
DATASET ACTIVATE  deaggregatie.
FILTER OFF.
USE ALL.
SELECT IF (tussenvar_nietbewoond > 0).
EXECUTE.
rename variables tussenvar_nietbewoond = kubus2210_woongelegenheden.
compute v2210_eigenaar_huurder=0.

DATASET ACTIVATE  subset.
DATASET COPY  temp1.
DATASET ACTIVATE  temp1.
FILTER OFF.
USE ALL.
SELECT IF (v2210_huurders > 0).
EXECUTE.
rename variables v2210_huurders = kubus2210_woongelegenheden.
compute v2210_eigenaar_huurder=2.

DATASET ACTIVATE  subset.
DATASET COPY  temp2.
DATASET ACTIVATE  temp2.
FILTER OFF.
USE ALL.
SELECT IF (v2210_inwonend_eigenaarsgezin > 0).
EXECUTE.
rename variables v2210_inwonend_eigenaarsgezin= kubus2210_woongelegenheden.
compute v2210_eigenaar_huurder=1.

DATASET ACTIVATE  deaggregatie.
ADD FILES /FILE=*
  /FILE='temp2'
  /FILE='temp1'.
EXECUTE.
dataset close temp1.
dataset close temp2.

* einde de-aggregatie.

* aanmaken variabele om de de-aggregatie duidelijk aan te tonen.
sort cases eigendom_id (a).
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=eigendom_id
  /deaggregatieteller=N.





string geolevel (a15).
compute geolevel="statsec".
RENAME VARIABLES jaartal=period.
DATASET DECLARE kubus1.
AGGREGATE
  /OUTFILE='kubus1'
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_eigenaar_huurder v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_bouwvorm v2210_eengezin_meergezin
  /kubus2210_woongelegenheden=SUM(kubus2210_woongelegenheden).
DATASET ACTIVATE kubus1.
dataset copy gemeente.
dataset activate gemeente.
alter type geoitem (a5).
recode geoitem ('12030'='12041')
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
alter type geoitem (a9).
compute geolevel="gemeente".
DATASET DECLARE kubus2.
AGGREGATE
  /OUTFILE='kubus2'
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_eigenaar_huurder v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_bouwvorm v2210_eengezin_meergezin
  /kubus2210_woongelegenheden=SUM(kubus2210_woongelegenheden).



DATASET ACTIVATE kubus1.
ADD FILES /FILE=*
  /FILE='kubus2'.
EXECUTE.

dataset close gemeente.
dataset close kubus2.
dataset close deaggregatie.
dataset close subset.


SAVE TRANSLATE OUTFILE='C:\temp\kadaster\upload\kubus_woongelegenheden_2019.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES.
