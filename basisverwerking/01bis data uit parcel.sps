* Encoding: windows-1252.
* map met alle kadasterdata.
DEFINE datamap () 'H:\data\kadaster\' !ENDDEFINE.
* dit gaat ervan uit dat je een map "upload" hebt in deze map.

* map met alle data die van Github komt.
DEFINE github () 'C:\github\' !ENDDEFINE.
* je hebt met name de repository "gebiedsniveaus" nodig.

* jaartal waarvoor we werken.
DEFINE datajaar () '2022' !ENDDEFINE.



PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE="C:\temp\kadaster\2022\KAD_2022_parcel.txt"
  /DELCASE=LINE
  /DELIMITERS="\t"
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  propertySituationIdf f9.0
  divCad f5.0
  section a1
  primaryNumber f4.0
  bisNumber f2.0
  exponentLetter a1
  exponentNumber f3.0
  partNumber a5
  capakey A17
  order a2
  nature a3
  descriptPrivate a35
  block f1.0
  floor f4.0
  floorSituation a10
  crossDetail a10
  matUtil a10
  notTaxedMatUtil a10
  nisCom f5.0
  street_situation a50
  street_translation a50
  street_code a5
  number a50
  polWa a7
  surfaceNotTaxable f7.0
  surfaceTaxable f7.0
  surfaceVerif a1
  constructionYear f4.0
  soilIndex f1.0
  soilRent f1.0
  cadastralIncomePerSurface f5.0
  cadastralIncomePerSurfaceOtherDi f3.0
  numberCadastralIncome f1.0
  charCadastralIncome a1
  cadastralIncome f10.0
  dateEndExoneration a15
  decrete f3.0
  constructionIndication f3.0
  constructionType a1
  floorNumberAboveground f3.0
  garret f1.0
  physModYear a4.0
  constructionQuality a1
  garageNumber f4.0
  centralHeating f1.0
  bathroomNumber f4.0
  housingUnitNumber f4.0
  placeNumber f4.0
  builtSurface f8.0
  usedSurface f6.0
  dateSituation edate10
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME parcel WINDOW=FRONT.

rename variables propertySituationIdf=eigendom_id.

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
/floor=first(floor).
dataset activate parcelagg.




* indien nog niet geopend.
GET
  FILE=datamap +  'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

dataset activate eigendommen.
sort cases eigendom_id (a).



DATASET ACTIVATE eigendommen.
MATCH FILES /FILE=*
  /TABLE='parcelagg'
  /BY eigendom_id.
EXECUTE.

* AANTAL KAMERS IN WONINGEN..

* woonplaatsen of kamers.
* ook ingevuld voor andere dingen dan wooneenheden.
if v2210_woonfunctie=1 v2210_aantal_kamers=placeNumber.
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

if aantal_kamers>0 v2210_wgl_met_kamers=woongelegenheden.
if aantal_kamers>0 v2210_woning_met_kamers=wooneenheden.

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
string aard (a4).
if CHAR.INDEX(descript_clean,'A')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'B')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'BU')=1 aard=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'G')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'HA')=1 aard=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'K')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'KA')=1 aard=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'M')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'P')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'S')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'T')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'VITR')=1 aard=char.substr(descript_clean,1,4).

* in theorie volgt onmiddelijk op aard de verdieping.
string verdiep0 (a254).
if aard~="" verdiep0=char.substr(descript_clean,length(ltrim(rtrim(aard)))+1).
* normaal gezien volgt op het verdiep een slash of niets meer.
string verdiep1 (a254).
compute verdiep1=char.substr(verdiep0,1,CHAR.INDEX(verdiep0,"/")-1).
do if CHAR.INDEX(verdiep0,"/")=0.
compute verdiep1=char.substr(verdiep0,1).
end if.

* maar soms hangen er nog spaties of punten voor het verdiep begint.
compute verdiep1=ltrim(ltrim(verdiep1,".")).

* soms staat er een punt in het verdiep, of een liggend streepje een @ of een &.
* in beide gevallen gaan we ervan uit dat het verdiep dan omschreven staat vOOr dat punt of streepje.
* OPMERKING: soms staat er iets als 1.2.3; dit wijzen we toe als 1. Wellicht zou 3 beter zijn. Misschien ook niet. 
* Alleszins is het wat complexer om die drie op te pikken zonder andere problemen te introduceren.
if CHAR.INDEX(verdiep1,".")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,".")-1).
if CHAR.INDEX(verdiep1,"-")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"-")-1).
if CHAR.INDEX(verdiep1," ")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1," ")-1).
if CHAR.INDEX(verdiep1,"@")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"@")-1).
if CHAR.INDEX(verdiep1,"&")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"&")-1).

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
if aard="S" | aard="G" | aard="K" | aard="P" | aard="B" | aard="VITR" verdiep=$sysmis.

* enkele records hebben een belachelijk hoog aantal verdiepingen.
* vanaf hoeveel verdiepen het absurd wordt is natuurlijk gebiedsafhankelijk.
if verdiep>10 verdiep=$sysmis.

* einde toewijzing verdiep per rij. 
* we aggregeren per perceel om het aantal verdiepen van gebouwen te benaderen.

* opkuisen aard.
rename variables aard=aard0.
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
into aard.
value labels aard
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
if misisng(verdiep) verdiep=floor.

* hoogste gebouw van Belgie heeft 36 verdiepen.
recode n_verdiep verdiep (37 thru highest=sysmis).


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

* negatief aantal verdiepen kan niet.
recode verdiepen_perceel verdiepen_inc_dakverdiep (lowest thru 0=0).

variable labels verdiep "hoeveelste verdiep (floor en descriptprivate)".
variable labels verdiepen_perceel "aantal verdiepen perceel (descriptprivate en floorNumberAboveground)".
variable labels verdiepen_inc_dakverdiep "aantal verdiepen perceel (+garret)".

* EINDE VERDIEPINGEN.




* BEWOONBARE OPPERVLAKTE.
* cleaning vereist bouwlagen (zie hierboven).
* usedSurface = nuttige oppervlakte.
compute nuttige_oppervlakte_origineel=usedSurface.



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
if v2210_woonfunctie=1 opp_per_wooneenheid=usedsurface/wooneenheden.
* tel enkel als woonoppervlakte indien woonfunctie en minder dan 2000 en groter dan 10.
if opp_per_wooneenheid<2000 & opp_per_wooneenheid> 9.99 & v2210_woonfunctie=1 v2210_woonoppervlakte=usedsurface.
compute  opp_per_wooneenheid=v2210_woonoppervlakte/wooneenheden.
do if v2210_woonoppervlakte>0.
compute v2210_wooneenheid_opp=wooneenheden.
compute v2210_wgl_opp=wooneenheden.
end if.

* einde oppervlakte cleaning

dataset close parcelagg.
dataset close parcel.


SAVE OUTFILE=datamap +  'werkbestanden\eigendom_' + datajaar + '_basisafspraken_verrijkt.sav'
  /COMPRESSED.



rename variables stat_sector=geoitem.
rename variables jaartal=period.



DATASET ACTIVATE eigendommen.
DATASET DECLARE agg0.
AGGREGATE
  /OUTFILE='agg0'
  /BREAK=period capakey geoitem
  /verdiepen_inc_dakverdiep_max=MAX(verdiepen_inc_dakverdiep).
dataset activate agg0.

FILTER OFF.
USE ALL.
SELECT IF (verdiepen_inc_dakverdiep_max >  - 1).
EXECUTE.

DATASET DECLARE aggverd.
AGGREGATE
  /OUTFILE='aggverd'
  /BREAK=period geoitem
  /v2210_som_verdiepen=SUM(verdiepen_inc_dakverdiep_max)
  /v2210_prc_met_verdiepteller=N.

DATASET ACTIVATE eigendommen.
dataset close agg0.
DATASET DECLARE aggr.
AGGREGATE
  /OUTFILE='aggr'
  /BREAK=geoitem period
/v2210_aantal_kamers=sum(v2210_aantal_kamers)
/v2210_wgl_met_kamers=sum(v2210_wgl_met_kamers)
/v2210_woning_met_kamers=sum(v2210_woning_met_kamers)
/v2210_woonoppervlakte=sum(v2210_woonoppervlakte)
/v2210_wooneenheid_opp=sum(v2210_wooneenheid_opp)
/v2210_wgl_opp=sum(v2210_wgl_opp).
dataset activate aggr.

DATASET ACTIVATE aggr.
MATCH FILES /FILE=*
  /TABLE='aggverd'
  /BY geoitem period.
EXECUTE.
dataset close aggverd.





GET
  FILE=github + 'gebiedsniveaus\verzamelbestanden\verwerkt_alle_gebiedsniveaus.sav'.
DATASET NAME allegebieden WINDOW=FRONT.

DATASET ACTIVATE allegebieden.
DATASET DECLARE uniekstatsec.
AGGREGATE
  /OUTFILE='uniekstatsec'
  /BREAK=statsec gewest
  /N_BREAK=N.
dataset activate uniekstatsec.
dataset close allegebieden.
delete variables N_BREAK.
rename variables statsec=geoitem.

DATASET ACTIVATE aggr.
MATCH FILES /FILE=*
  /FILE='uniekstatsec'
  /BY geoitem.
EXECUTE.
dataset close uniekstatsec.

* Dit is enkel nodig omdat dit missing is voor de lege sectoren.
compute period=number(datajaar,f4.0).

string geolevel (a7).
compute geolevel="statsec".




* regel1: indien gebied onbekend: enkel dingen inlezen indien nodig. Alle zinloze waarden vervangen we door -99996.
* regel 2: indien Brussel: ALLES is een brekende missings -99999 (TOGA).
* regel 3: indien in een niet-onbekende statsec (alles behalve iets met "zzzz" is 0 = 0 en ook missing=0.

* regel 1.
do if char.index(geoitem,"ZZZZ")>0.
recode v2210_aantal_kamers
v2210_wgl_met_kamers
v2210_woning_met_kamers
v2210_woonoppervlakte
v2210_wooneenheid_opp
v2210_wgl_opp
v2210_som_verdiepen
v2210_prc_met_verdiepteller
(0=-99996) (missing=-99996).
end if.

* regel 2.
do if gewest=4000.
recode v2210_aantal_kamers
v2210_wgl_met_kamers
v2210_woning_met_kamers
v2210_woonoppervlakte
v2210_wooneenheid_opp
v2210_wgl_opp
v2210_som_verdiepen
v2210_prc_met_verdiepteller
(else=-99999).
end if.

* regel 3.
do if gewest=2000 & char.index(geoitem,"ZZZZ")=0 .
recode v2210_aantal_kamers
v2210_wgl_met_kamers
v2210_woning_met_kamers
v2210_woonoppervlakte
v2210_wooneenheid_opp
v2210_wgl_opp
v2210_som_verdiepen
v2210_prc_met_verdiepteller
(missing=0).
end if.

EXECUTE.
delete variables gewest.



SAVE TRANSLATE OUTFILE=datamap + 'upload\oppervlakte_hoogte_kamers' + datajaar + '.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/replace.


