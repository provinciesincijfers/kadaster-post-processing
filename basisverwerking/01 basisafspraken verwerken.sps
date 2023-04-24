* Encoding: windows-1252.

* todo bij verwerking 2022: opletten dat bouwjaar/wijzigingsjaar 2021 in de juiste categoriën terechtkomt in platte onderwerpen en kubussen.

* map met alle kadasterdata.
DEFINE datamap () 'h:\data\kadaster\' !ENDDEFINE.
* dit gaat ervan uit dat je een map "upload" hebt in deze map.

* map met alle data die van Github komt.
DEFINE github () 'C:\github\' !ENDDEFINE.


* jaartal waarvoor we werken.
DEFINE datajaar () '2018' !ENDDEFINE.



GET
  FILE=datamap+ 'werkbestanden\eigendom_' + datajaar + '.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

* vanaf 2021 betekent "wooneenheden=999" dat er geen wooneenheden zijn. In 2020 kwam dit nooit voor.
recode wooneenheden (999=sysmis).


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


DATASET ACTIVATE bzl.
DATASET DECLARE aggr.
AGGREGATE
  /OUTFILE='aggr'
  /BREAK=provincie jaartal niscode stat_sector
  /bewoning_zonder_link=SUM(bewoning_zonder_link).

DATASET ACTIVATE eigendommen.
ADD FILES /FILE=*
  /FILE='aggr'.
EXECUTE.
dataset close bzl.
dataset close aggr.

* EINDE LUIK 3.

* LUIK 4.
compute LUIK4=$sysmis.


GET
  FILE=datamap +  'werkbestanden\parcel_' + datajaar + '.sav'.
DATASET NAME parcel WINDOW=FRONT.

alter type nature (f3.0).
sort cases nature (a).

* indeling ophalen.
PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=github + "kadaster-post-processing\koppeltabellen\nature_nisindeling.csv"
  /DELCASE=LINE
  /DELIMITERS=";"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  Nature F3.0
  nis_indeling A3
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME nature WINDOW=FRONT.
sort cases nature (a).

DATASET ACTIVATE parcel.
MATCH FILES /FILE=*
  /TABLE='nature'
  /BY Nature.
EXECUTE.
dataset close nature.

* in dit bestand zijn er dubbels, maar in de onderwerpen die we nodig hebben, lijken de waarden steeds identiek.
DATASET ACTIVATE parcel.
DATASET DECLARE parcelagg.
AGGREGATE
  /OUTFILE='parcelagg'
  /BREAK=eigendom_id 
/builtSurface=FIRST(builtSurface)
/usedSurface=FIRST(usedSurface)
/placeNumber=FIRST(placeNumber)
/floorNumberAboveground=FIRST(floorNumberAboveground)
/descriptPrivate=FIRST(descriptPrivate)
/garret=FIRST(garret)
/floor=first(floor)
/nature=first(nature)
/surfaceNotTaxable=sum(surfaceNotTaxable)
/surfaceTaxable=sum(surfaceTaxable)
/nis_indeling=first(nis_indeling).
dataset activate parcelagg.


dataset activate eigendommen.
sort cases eigendom_id (a).

MATCH FILES /FILE=*
  /TABLE='parcelagg'
  /BY eigendom_id.
EXECUTE.
dataset close parcelagg.
dataset close parcel.

* oppervlaktes landgebruik.
recode surfaceNotTaxable
surfaceTaxable (missing=0).
compute surface_total=surfaceNotTaxable+surfaceTaxable.


* AANTAL KAMERS IN WONINGEN..

* woonplaatsen of kamers.
* ook ingevuld voor andere dingen dan wooneenheden.
if woonfunctie=1 v2210_aantal_kamers=placeNumber.
* aantal kamers per woongelegenheid.
compute kamers_per_woning=v2210_aantal_kamers/woongelegenheden.

* er zijn werkelijk heel extreme waarden (komt niet voor bij kastelen, en die hebben wel eens veel kamers).
do if subtype_woning="Kasteel".
recode kamers_per_woning (lowest thru 0.9999=sysmis).
else.
recode kamers_per_woning (lowest thru 0.9999=sysmis) (31 thru highest=sysmis).
end if.

* indien extreme waarde, ook de teller zelf verwijderen.
if missing(kamers_per_woning) v2210_aantal_kamers=$sysmis.

variable labels kamers_per_woning 'kamers per woning (gecleaned)'.
variable labels v2210_aantal_kamers 'kamers in woningen (gecleaned)'.

if v2210_aantal_kamers>0 v2210_wgl_met_kamers=woongelegenheden.
if v2210_aantal_kamers>0 v2210_woning_met_kamers=wooneenheden.

* EINDE AANTAL KAMERS IN WONINGEN..


* VERDIEPINGEN.


* VERDIEP EN AARD.

* floorNumberAboveground, garret EN descriptPrivate.
* floorNumberAboveground bevat het aantal bouwlagen voor dingen met verdiepingen. Bijvoorbeeld een huis of een appartementsblok. 
* floor bevat de verdieping zelf van de eigendom (vb een apprtement op de derde verdieping).
* descriptPrivate gaat over waar op het perceel een perceeldeel lig. Dit bevat indien nodig de verdieping van het ding in kwestie. Bijvoorbeeld een appartement. 
*-> in descriptPrivate zijn de voorlooptekens "  #' verwijderd.
* garret gaat over bewoonde zolders.

* er zijn heel wat panden met nul verdiepen (1 bouwlaag), maar slechts zelden is dit bij een type gebouw waar je dat niet zou verwachten.
* we maken een variabele die op gebouwniveau van toepassing is (n_verdiep) en een die op wooneenheden van toepassing is (verdiep).
* omdat gebouwen geen eenheid zijn in het kadaster, moeten we helaas aggregeren op perceel. We nemen dan het hoogste van de twee variabelen en tellen er eventueel nog de bewoonde zolders bij.

* hetzelfde perceel kan huizen en appartementen hebben, met elk een eigen aantal verdiepen.
* doorgaans heeft een perceel met appartementen een enkele record met het aantal verdiepen, de rest staat op missing.
* in Antwerpen bestaat een huis met 18 verdiepen :)

* enkel van "buildings" (een enkele eigenaar) worden verdiepen geregistreerd in de constructiecode, niet van woningen in een building .
* daarom is het nodig om ook het veld "sl2/descriptPrivate" (gedetailleerde ligging of iets dergelijks) te gebruiken.

compute n_verdiep=floorNumberAboveground-1.
variable labels n_verdiep "aantal verdiepen (floorNumberAboveground-1)".


* sl2 bevat mogelijk zowel de "aard" als het verdiep.
* in theorie kan de aard enkel onderstaande dingen zijn.
string descript_clean (a35).
compute descript_clean=ltrim(ltrim(ltrim(ltrim(descriptPrivate,'.'),'"'),'/'),'#').
string aard_descript (a4).
if CHAR.INDEX(descript_clean,'A')=1 aard_descript=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'B')=1 aard_descript=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'BU')=1 aard_descript=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'G')=1 aard_descript=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'HA')=1 aard_descript=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'K')=1 aard_descript=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'KA')=1 aard_descript=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'M')=1 aard_descript=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'P')=1 aard_descript=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'S')=1 aard_descript=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'T')=1 aard_descript=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'VITR')=1 aard_descript=char.substr(descript_clean,1,4).

* in theorie volgt onmiddelijk op aard de verdieping.
string verdiep0 (a254).
if aard_descript~="" verdiep0=char.substr(descript_clean,length(ltrim(rtrim(aard_descript)))+1).
* normaal gezien volgt op het verdiep een slash of niets meer.
string verdiep1 (a254).
compute verdiep1=char.substr(verdiep0,1,CHAR.INDEX(verdiep0,"/")-1).
do if CHAR.INDEX(verdiep0,"/")=0.
compute verdiep1=char.substr(verdiep0,1).
end if.

* maar soms hangen er nog spaties of punten voor het verdiep begint.
compute verdiep1=ltrim(ltrim(verdiep1,".")).


* soms staat er een punt in het verdiep, of een liggend streepje een @ , & of een +.
* in beide gevallen gaan we ervan uit dat het verdiep dan omschreven staat vOOr dat punt of streepje.
* OPMERKING: soms staat er iets als 1.2.3; dit wijzen we toe als 1. Wellicht zou 3 beter zijn. Misschien ook niet. 
* Alleszins is het wat complexer om die drie op te pikken zonder andere problemen te introduceren.
if CHAR.INDEX(verdiep1,".")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,".")-1).
if CHAR.INDEX(verdiep1,"-")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"-")-1).
if CHAR.INDEX(verdiep1," ")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1," ")-1).
if CHAR.INDEX(verdiep1,"@")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"@")-1).
if CHAR.INDEX(verdiep1,"&")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"&")-1).
if CHAR.INDEX(verdiep1,"+")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"+")-1).

* we gaan ervan uit dat als het verdiepnummer nu nog altijd begint met OG, GV, TV of BE, alles wat erachter komt weg mag.
if CHAR.INDEX(verdiep1,"GV")=1 verdiep1=char.substr(verdiep1,1,2).
if CHAR.INDEX(verdiep1,"OG")=1  verdiep1=char.substr(verdiep1,1,2).
if CHAR.INDEX(verdiep1,"TV")=1 verdiep1=char.substr(verdiep1,1,2).

* we zetten het om naar een numerieke waarde.
compute verdiep=number(verdiep1,f3.0).
recode verdiep1 ('GV'=0) ('OG'=-1) ('TV'=0.5) ('BE'=0.75) into verdiep.
* opmerking: gv=gelijkvloers, og=ondergronds, er kunnen eventueel meerdere verdiepen of lokalen zijn, 
TV=tussenverdiep, 'BE'=bel-etage.


* indien S, G, K, P, B  dan is het een nummer, geen verdiep.
* indien VITR dan is het nog iets anders.
if aard_descript="S" | aard_descript="G" | aard_descript="K" | aard_descript="P" | aard_descript="B" | aard_descript="VITR" verdiep=$sysmis.

* enkele records hebben een belachelijk hoog aantal verdiepingen.
* vanaf hoeveel verdiepen het absurd wordt is natuurlijk gebiedsafhankelijk.
* we leggen de grens op 10, omdat er vrij veel ruis is op de data.
if verdiep>10 verdiep=$sysmis.

* einde toewijzing verdiep per rij. 
* we aggregeren per perceel om het aantal verdiepen van gebouwen te benaderen.

* opkuisen aard.
rename variables aard_descript=aard0.
recode aard0 
('A'=1)
('B'=2)
('BU'=3)
('G'=4)
('HA'=5)
('K'=6)
('KA'=7)
('M'=8)
('P'=9)
('S'=10)
('T'=11)
('VITR'=12)
into aard_descript.
value labels aard_descript
1 'wooneenheid'
2 'bergplaats'
3 'bureaus'
4 'garage'
5 'handel'
6 'kelder'
7 'kamer'
8 'zolderkamer'
9 'parking'
10 'standplaats'
11 'tuin'
12 'vitrine'.
execute.
delete variables verdiep0 verdiep1  aard0 descript_clean.
* opmerking: enkele rijen krijgen een foute 'aard', omdat bijvoorbeeld BOUWGROND in dit veld gebruikt wordt, wat volgens de documentatie niet kan.


* verrijken met de officiele variabele "floor".
* wanneer deze beschikbaar is, dan is deze juister dan verdiep.
if floor>=0 verdiep=floor.

* hoogste gebouw van Belgie heeft 36 verdiepen.
recode n_verdiep verdiep (37 thru highest=sysmis).
* eigendommen met een negatief aantal verdiepen tellen we niet mee.
recode n_verdiep (lowest thru 0=sysmis) (37 thru highest=sysmis).

* enkel verdiepen tellen op bebouwde aarden.
if char.substr(nis_indeling,1,1)="1" n_verdiep=$sysmis.
if char.substr(nis_indeling,1,1)="1" verdiep=$sysmis.

* variabele om de 'beste' verdiepschatting te maken per perceel.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /n_verdiep_max=MAX(n_verdiep) 
  /verdiep_max=MAX(verdiep)
  /dakverdiep_max=max(garret).

compute verdiepen_perceel=max(n_verdiep_max,verdiep_max).
if missing(verdiepen_perceel) verdiepen_perceel=n_verdiep_max.
if missing(verdiepen_perceel) verdiepen_perceel=verdiep_max.
compute verdiepen_perceel=trunc(verdiepen_perceel).
compute verdiepen_inc_dakverdiep=verdiepen_perceel.
if dakverdiep_max=1 verdiepen_inc_dakverdiep=verdiepen_perceel+1.
EXECUTE.
delete variables n_verdiep_max verdiep_max dakverdiep_max.

freq verdiepen_perceel verdiepen_inc_dakverdiep.
* negatief aantal verdiepen op een perceel kan niet.
recode verdiepen_perceel verdiepen_inc_dakverdiep (lowest thru 0=0).
freq verdiepen_perceel verdiepen_inc_dakverdiep.

variable labels verdiep "hoeveelste verdiep (floor en descriptprivate)".
variable labels verdiepen_perceel "aantal verdiepen perceel (floor, descriptprivate en floorNumberAboveground)".
variable labels verdiepen_inc_dakverdiep "aantal verdiepen perceel (+garret)".

* EINDE VERDIEPINGEN.




* BEWOONBARE OPPERVLAKTE.
* cleaning vereist bouwlagen (zie hierboven).
* usedSurface = nuttige oppervlakte.
*compute nuttige_oppervlakte_origineel=usedSurface.



* cleanen oppervlaktes.
* creeer context op perceelsniveau.
*AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=capakey
  /oppervlakte_sum=SUM(oppervlakte) 
  /builtSurface_sum=SUM(builtSurface) 
  /usedSurface_sum=SUM(usedSurface).

* hou enkel oppervlaktes over als ze realistisch zijn.
* bereken opp per wooneenheid op wooneigendommen.
if woonfunctie=1 opp_per_wooneenheid=usedsurface/wooneenheden.
* tel enkel als woonoppervlakte indien woonfunctie en minder dan 2000 en groter dan 10.
if opp_per_wooneenheid<2000 & opp_per_wooneenheid> 9.99 & woonfunctie=1 v2210_woonoppervlakte=usedsurface.
compute  opp_per_wooneenheid=v2210_woonoppervlakte/wooneenheden.
do if v2210_woonoppervlakte>0.
compute v2210_wooneenheid_opp=wooneenheden.
compute v2210_wgl_opp=woongelegenheden.
end if.

* einde oppervlakte cleaning


variable labels AFGELEIDE_VARIABELEN 'D&A afgeleiden variabelen'.
variable labels LUIK1 'LUIK1: localisatie'.
variable labels stat_sector 'statsec (uit meest recente koppeling.txt + correcties)'.
variable labels capa5 'capa5 (voor niet te lokaliseren percelen)'.
variable labels niscode 'niscode (uit meest recente koppeling.txt)'.
variable labels LUIK2 'LUIK2: basisconcepten'.
variable labels bewoond 'al of niet bewoond'.
variable labels woonfunctie 'woonfunctie (op aard)'.
variable labels wgl_woonfunctie 'woongelegenheden op eigendom met woonfunctie'.
variable labels type_woonaanbod 'soort woning (op aard)'.
variable labels woongelegenheden_perceel_tot 'totaal woongelegenheden op dit perceel (niet optelbaar!)'.
variable labels aantal_eigendommen 'totaal eigendommen op dit perceel (niet optelbaar!)'.
variable labels eengezin_meergezin 'eengezin (1) of meergezinswoning (2) (volgens aantal wgl. op perceel)'.
variable labels eigenaar_huurder 'huurder/eigenaar (0 onbekend/1 eigenaar/2 huurder/3 onbewoond)'.
variable labels hurende_huishoudens 'aantal huurders op eigendom'.
variable labels inwonend_eigenaarsgezin 'aantal eigenaars op eigendom'.
variable labels bouwjaar_clean 'bouwjaar (gecleaned)'.
variable labels laatste_wijziging_clean 'jaar laatste wijziging (gecleaned)'.
variable labels bouwjaar_cat 'categorie bouwjaren'.
variable labels bouwjaar_cat_wgl 'categorie bouwjaren (enkel ingevuld voor eig met wgl)'.
variable labels laatste_wijziging_cat 'categorie wijzigingsjaren'.
variable labels laatste_wijziging_cat_wgl 'categorie wijzigings (enkel ingevuld voor eig met wgl)'.
variable labels recentste_jaar 'recentste van bouwjaar en wijzigingsjaar'.
variable labels egw_open_bouwvorm 'egw in open bebouwing'.
variable labels egw_halfopen_bouwvorm 'egw in halfopen bebouwing'.
variable labels egw_gesloten_bouwvorm 'egw in gesloten bebouwing'.
variable labels egw_andere_bouwvorm 'egw anders/onbekend'.
variable labels LUIK3 'LUIK3: bewoning zonder link'.
variable labels bewoning_zonder_link 'huishoudens die niet gekoppeld konden worden aan kadaster (per statsec)'.
variable labels LUIK4 'LUIK4: data uit parcel'.
variable labels builtSurface 'builtSurface'.
variable labels usedSurface 'usedSurface'.
variable labels placeNumber 'placeNumber'.
variable labels floorNumberAboveground 'floorNumberAboveground'.
variable labels descriptPrivate 'descriptPrivate'.
variable labels garret 'garret'.
variable labels floor 'floor'.
variable labels nature 'nature'.
variable labels surfaceNotTaxable 'surfaceNotTaxable'.
variable labels surfaceTaxable 'surfaceTaxable'.
variable labels surface_total 'surface (som Not/taxable)'.
variable labels nis_indeling 'nis indeling (statbel bodembezetting) van nature'.
variable labels v2210_aantal_kamers 'kamers (enkel indien woonfunctie)'.
variable labels kamers_per_woning 'kamers per wgl'.
variable labels v2210_wgl_met_kamers 'aantal wgl met bekend aantal kamers'.
variable labels v2210_woning_met_kamers 'aantal woningen met bekend aantal kamers'.
variable labels n_verdiep 'aantal verdiepen van het eigendom'.
variable labels verdiep 'verdiep waarop het eigendom ligt'.
variable labels aard_descript 'type goed volgens descriptprivate'.
variable labels verdiepen_perceel 'aantal verdiepen van het perceel'.
variable labels verdiepen_inc_dakverdiep 'aantal verdiepen van het perceel (dakverdieping meegerekend)'.
variable labels opp_per_wooneenheid 'nuttige oppervlakte per wooneenheid'.
variable labels v2210_woonoppervlakte 'nuttige oppervlakte van wooneenheden'.
variable labels v2210_wooneenheid_opp 'wooneenheden met gekende nuttige oppervlakte'.
variable labels v2210_wgl_opp 'wgl met gekende nuttige oppervlakte'.



SAVE OUTFILE= datamap +  'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sav'
  /COMPRESSED.

*SAVE TRANSLATE OUTFILE=datamap + 'werkbestanden\eigendom_' + datajaar + '_basisafspraken.csv'
  /TYPE=CSV
  /ENCODING='Locale'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES
/replace.

*SAVE TRANSLATE OUTFILE=datamap + 'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sas7bdat'
  /TYPE=SAS
  /VERSION=7
  /PLATFORM=WINDOWS
  /ENCODING='Locale'
  /MAP
  /REPLACE.
