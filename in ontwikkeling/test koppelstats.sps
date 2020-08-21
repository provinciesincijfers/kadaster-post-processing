* Encoding: windows-1252.


GET
  FILE='C:\temp\kadaster\werkbestanden\koppeltabel_rrgezinshoofd_eigendom.sav'.
DATASET NAME eigadres WINDOW=FRONT.

GET
  FILE='C:\temp\kadaster\werkbestanden\eigendom_2019.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

GET 
  SAS DATA='C:\temp\overstroming\i_lhc2_2019.sas7bdat'.
DATASET NAME bevolking WINDOW=FRONT. 

* todo: uitzuiveren gezinshoofden die bij meerdere adressen genoemd worden.

if NATIONAAL_NUMMER = RRNR_HOOFDPERSOON & refpers = "N" collectief=1.
if  NATIONAAL_NUMMER = RRNR_HOOFDPERSOON & refpers = "J" privaat=1.
if  NATIONAAL_NUMMER ~= RRNR_HOOFDPERSOON gezinslid=1.
compute inwoner=1.
EXECUTE.



dataset activate eigendommen.

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


* huurder/eigenaar
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



match files
/file=*
/keep=
eigendom_id
v2210_type_woonaanbod
eengezin_meergezin
eigenaar_huurder
v2210_huurders
v2210_inwonend_eigenaarsgezin.
EXECUTE.

sort cases eigendom_id (a).

dataset activate eigadres.
sort cases eigendom_id (a).
MATCH FILES /FILE=*
  /TABLE='eigendommen'
  /BY eigendom_id.
EXECUTE.

dataset close eigendommen.


DATASET ACTIVATE bevolking.
DATASET DECLARE bevhh.
AGGREGATE
  /OUTFILE='bevhh'
  /BREAK=NATIONAAL_NUMMER hhtype hhpos
  /N_BREAK=N.

DATASET DECLARE bevhh.
AGGREGATE
  /OUTFILE='bevhh'
  /BREAK=NATIONAAL_NUMMER hhtype
  /N_BREAK=N.
dataset activate bevhh.
delete variables n_break.

dataset activate eigadres.
sort cases NATIONAAL_NUMMER (a).
MATCH FILES /FILE=*
  /TABLE='bevhh'
  /BY NATIONAAL_NUMMER.
EXECUTE.

dataset close bevhh.

value labels hhtype
1 'alleenwonend'
2 'gehuwd paar zonder kinderen'
3 'gehuwd paar met kinderen'
4 'ongehuwd samenwonend paar zonder kinderen'
5 'ongehuwd samenwonend paar met minstens 1 minderjarig (LIPRO) kind'
6 'eenoudergezin'
7 'ander type huishouden'
8 'collectief hh?'.




DATASET ACTIVATE eigadres.
* Identify Duplicate Cases.
SORT CASES BY eigendom_id(A).
MATCH FILES
  /FILE=*
  /BY eigendom_id
  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
VARIABLE LABELS  MatchSequence 'Sequential count of matching cases'.
VARIABLE LEVEL  MatchSequence (SCALE).
EXECUTE.

compute eigenaar_huurder_backup=eigenaar_huurder.
if matchsequence=1 & v2210_huurders>0 & v2210_inwonend_eigenaarsgezin = 1 eigenaar_huurder= 1.
if matchsequence>1 & v2210_huurders>0 & v2210_inwonend_eigenaarsgezin = 1 eigenaar_huurder= 2.
EXECUTE.
