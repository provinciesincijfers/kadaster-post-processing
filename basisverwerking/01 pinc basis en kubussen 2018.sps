* Encoding: windows-1252.


GET
  FILE='C:\temp\kadaster\werkbestanden\eigendom_2018.sav'.
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
** in enkele honderden gevallen gaat is mis. Oorzaak: allicht iets mis met de geometrie, of ze ontbreken volledig in de geometrie, of er is iets mis met de capakey.
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


* toevoegen alle gebieden om nullen in te lezen!

GET
  FILE='C:\github\gebiedsniveaus\verzamelbestanden\verwerkt_alle_gebiedsniveaus.sav'.
DATASET NAME allegebieden WINDOW=FRONT.

DATASET ACTIVATE allegebieden.
DATASET DECLARE uniekstatsec.
AGGREGATE
  /OUTFILE='uniekstatsec'
  /BREAK=statsec
  /N_BREAK=N.
dataset activate uniekstatsec.
dataset close allegebieden.
delete variables N_BREAK.
rename variables statsec=stat_sector.

DATASET ACTIVATE eigendommen.
ADD FILES /FILE=*
  /FILE='uniekstatsec'.
EXECUTE.

DATASET CLOSE uniekstatsec.


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
  /aantal_perceeldelen=N.

* deze classificatie geeft aan één rijtje een zinvolle waarde. Aangezien de rest op missing blijft staan, ga je doorgaans direct eindigen met goede resultaten als je 
berekeningen maakt die dit veld gebruiken.
if woongelegenheden_perceel_tot =1 eengezin_meergezin = 1.
if woongelegenheden_perceel_tot >1 eengezin_meergezin = 2.
value labels eengezin_meergezin
1 "perceel met 1 woongelegenheid"
2 "perceel met meerdere woongelegenheden".

* indicatoren eengezins/meergezinswoningen. Dit is een indeling van de woonvoorraad (wv).
* al deze indicatoren kunnen eenvoudig opgeteld worden.

if eengezin_meergezin=1 v2210_wv_eengezinswoningen=woongelegenheden.
if eengezin_meergezin=2 v2210_wv_meergezinswoningen=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot <=5 v2210_wv_mg_2_5=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot > 5 & woongelegenheden_perceel_tot <=10 v2210_wv_mg_6_10=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot >10 v2210_wv_mg_11p=woongelegenheden.


* huurder/eigenaar
** tellling van huishoudens die we hebben kunnen koppelen
* strikt gezien niet nodig: teller aantal teruggevonden huishoudens.
compute v2210_huishoudens=huidig_bewoond.

* classificering van eigendommen naar eigenaars volgens type.
recode bewoner_code ('A'=1) ('E'=1) ('G' = 1) ('H' = 2) (else=0) into eigenaar_huurder.
if huidig_bewoond=0 eigenaar_huurder = 3.
value labels eigenaar_huurder
0 'onbekend'
1 'eigenaar in brede zin'
2 'huurder'
3 'onbewoond'.
freq eigenaar_huurder.
** er zouden geen onbekende mogen overblijven.

* indicatoren.
* huishoudens in verhuurde wooneenheden.
** omvat alle woningen in verhuurde eigendommen.
if eigenaar_huurder = 2 v2210_huurders=huidig_bewoond.
** MAAR OOK extra woningen in eigendommen met inwonende eigenaars.
if eigenaar_huurder = 1 & huidig_bewoond > 1 v2210_huurders = huidig_bewoond - 1.

* huishoudens eigenaarswoningen (de fout is kleiner als er slechts één inwonend gezin is op een eigendom).
if eigenaar_huurder = 1 v2210_inwonend_eigenaarsgezin=1.
EXECUTE.
** einde huurder/eigenaar



* EINDE LUIK 2.

* LUIK3: toevoegen bewoning zonder link.
compute LUIK3=$sysmis.

PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE="C:\temp\kadaster\2018\KAD_2018_bewoning_zonder_link.txt"
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

*voorbereiding.

* OPGELET: AANPASSEN.
compute period=2018.

string geolevel (a7).
compute geolevel="statsec".

rename variables stat_sector=geoitem.

DATASET DECLARE aggr.
AGGREGATE
  /OUTFILE='aggr'
  /BREAK=geolevel geoitem period
/v2210_woonvoorraad=sum(v2210_woonvoorraad)
/v2210_woonaanbod=sum(v2210_woonaanbod)
/v2210_wa_indiv=sum(v2210_wa_indiv)
/v2210_wa_app=sum(v2210_wa_app)
/v2210_wa_coll=sum(v2210_wa_coll)
/v2210_wv_eengezinswoningen=sum(v2210_wv_eengezinswoningen)
/v2210_wv_meergezinswoningen=sum(v2210_wv_meergezinswoningen)
/v2210_wv_mg_2_5=sum(v2210_wv_mg_2_5)
/v2210_wv_mg_6_10=sum(v2210_wv_mg_6_10)
/v2210_wv_mg_11p=sum(v2210_wv_mg_11p)
/v2210_huishoudens=sum(v2210_huishoudens)
/v2210_huurders=sum(v2210_huurders)
/v2210_inwonend_eigenaarsgezin=sum(v2210_inwonend_eigenaarsgezin)
/v2210_hh_onbekend=sum(v2210_hh_onbekend).

dataset activate aggr.
* enkel voor het zicht.
alter type v2210_woonvoorraad
v2210_woonaanbod
v2210_wa_indiv
v2210_wa_app
v2210_wa_coll
v2210_wv_eengezinswoningen
v2210_wv_meergezinswoningen
v2210_wv_mg_2_5
v2210_wv_mg_6_10
v2210_wv_mg_11p
v2210_huishoudens
v2210_huurders
v2210_inwonend_eigenaarsgezin
v2210_hh_onbekend (f8.0).

* ontbreken van gegevens betekent dat het er geen enkele is.
do if char.index(geoitem,"ZZZZ")=0.
recode v2210_woonvoorraad
v2210_woonaanbod
v2210_wa_indiv
v2210_wa_app
v2210_wa_coll
v2210_wv_eengezinswoningen
v2210_wv_meergezinswoningen
v2210_wv_mg_2_5
v2210_wv_mg_6_10
v2210_wv_mg_11p
v2210_huishoudens
v2210_huurders
v2210_inwonend_eigenaarsgezin 
v2210_hh_onbekend (missing=0).
end if.

* nullen in gebied onbekend verwijderen we.
do if char.index(geoitem,"ZZZZ")>0.
recode v2210_woonvoorraad
v2210_woonaanbod
v2210_wa_indiv
v2210_wa_app
v2210_wa_coll
v2210_wv_eengezinswoningen
v2210_wv_meergezinswoningen
v2210_wv_mg_2_5
v2210_wv_mg_6_10
v2210_wv_mg_11p
v2210_huishoudens
v2210_huurders
v2210_inwonend_eigenaarsgezin 
v2210_hh_onbekend (0=sysmis).
end if.

* indien er niets van nuttige info in een "gebied onbekend" staat, dan gooien we dit integraal weg.
compute houden=1.
if char.index(geoitem,"ZZZZ")>0 & missing(v2210_hh_onbekend) houden=0.
if max(v2210_woonvoorraad,
v2210_woonaanbod,
v2210_wa_indiv,
v2210_wa_app,
v2210_wa_coll,
v2210_wv_eengezinswoningen,
v2210_wv_meergezinswoningen,
v2210_wv_mg_2_5,
v2210_wv_mg_6_10,
v2210_wv_mg_11p,
v2210_huishoudens,
v2210_huurders,
v2210_inwonend_eigenaarsgezin,
v2210_hh_onbekend) > 0 houden=1.
EXECUTE.
DATASET ACTIVATE aggr.
FILTER OFF.
USE ALL.
SELECT IF (houden = 1).
EXECUTE.
delete variables houden.


SAVE TRANSLATE OUTFILE='C:\temp\kadaster\upload\pinc_basis_plat_2018.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/replace.


* dit stuk nog niet klaar.

* kubuslogica 1
** tel de woonvoorraad
**dimensies
- woonfunctie
- type woongelegenheid (3-deling + missing indien geen woonfunctie)
- bewoond ja/nee
- [vervalt] huurder/eigenaar
- eengezins/meergezins

compute kubus2210_woonvoorraad = v2210_woonvoorraad.
rename variables woonfunctie=v2210_woonfunctie.
*v2210_type_woonaanbod.
rename variables bewoond=v2210_bewoond.
rename variables eengezin_meergezin=v2210_eengezin_meergezin.

DATASET DECLARE kubus1.
AGGREGATE
  /OUTFILE='kubus1'
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_type_woonaanbod v2210_bewoond v2210_eengezin_meergezin
  /kubus2210_woonvoorraad=SUM(kubus2210_woonvoorraad)
  /N_BREAK=N.

* kubuslogica 2
** tel de huishoudens (huidig_bewoond)
**dimensies
- woonfunctie
- type woongelegenheid (3-deling + missing indien geen woonfunctie)
- [vervalt] bewoond ja/nee
- huurder/eigenaar > dit vereist nog een transformatie om afzonderlijke rijen voor huurders op een eigenaars-eigendom te kunnen tellen.

