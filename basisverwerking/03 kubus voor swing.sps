* Encoding: windows-1252.
* OPGELET: er is een harde compute period=2019 nodig vlak voor het aggregeren naar swing.

* map met alle kadasterdata.
DEFINE datamap () 'C:\temp\kadaster\' !ENDDEFINE.
* dit gaat ervan uit dat je een map "upload" hebt in deze map.

* map met alle data die van Github komt.
DEFINE github () 'C:\github\' !ENDDEFINE.

* jaartal waarvoor we werken.
DEFINE datajaar () '2018' !ENDDEFINE.


GET
  FILE=datamap +  'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sav'.
DATASET NAME eigendommen WINDOW=FRONT.



* LUIK 4: aggregatie naar Swing kubus.
compute LUIK4=$sysmis.



* we werken met WOONGELEGENHEDEN!

* en course de route hebben we al enkele variabelen gemaakt die rechtsreeks gebruikt kunnen worden als dimensieniveau.
* we hernoemen ze hier volgens de conventies voor kubusdimensieniveaus.
rename variables woonfunctie=v2210_woonfunctie.
rename variables bouwjaar_cat=v2210_bouwjaar_cat.
rename variables laatste_wijziging_cat=v2210_laatste_wijziging_cat.
rename variables eengezin_meergezin=v2210_eengezin_meergezin.
huidig_bewoond


* aangepaste dimensie nav vergadering 20201016.
compute v2210_bouwvorm=0.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Open bebouwing" v2210_bouwvorm = 1.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Halfopen bebouwing" v2210_bouwvorm = 2.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Gesloten bebouwing" v2210_bouwvorm = 3.
if v2210_eengezin_meergezin=2 v2210_bouwvorm = 4.



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
stat_sector
hurende_huishoudens
inwonend_eigenaarsgezin eigenaar_huurder 
v2210_woonfunctie v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_bouwvorm v2210_eengezin_meergezin.


*frequencies  v2210_woonfunctie eigenaar_huurder v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_bouwvorm v2210_eengezin_meergezin.

* de-aggregatie nodig vooraleer te aggregeren: eigenaar/huurder gaat over een eigendom, maar we willen uitspraken doen over woongelegenheden.

* we hebben al een teller met huurders en eigenaars, maar we hebben ook de "niet bewoonde" nodig om tot de woongelegenheden te komen.
* eens we die drie teleenheden hebben, dan kunnen we ze "onder elkaar" plakken in een nieuw bestand.
* om te kunnen rekenen, moeten de missings eerst weggewerkt worden.
recode hurende_huishoudens
huidig_bewoond
inwonend_eigenaarsgezin (missing=0).
* vervolgens zonder we de niet bewoonde af.
compute tussenvar_nietbewoond=woongelegenheden-hurende_huishoudens-inwonend_eigenaarsgezin.

* vervolgens maken we een bestand waarin we respectievelijk enkel de onbewoonde, de huurders en de eigenaars in onze uiteindelijke teleenheid steken. 

* eerst de onbewoonde.
DATASET ACTIVATE subset.
DATASET COPY  deaggregatie.
DATASET ACTIVATE  deaggregatie.
FILTER OFF.
USE ALL.
SELECT IF (tussenvar_nietbewoond > 0).
EXECUTE.
* in dit bestand tellen we enkel de onbewoonde.
rename variables tussenvar_nietbewoond = kubus2210_woongelegenheden.
* voor de onbewoonde is er uiteraard geen huurder of eigenaar.
compute v2210_eigenaar_huurder=0.

* dan de huurders.
DATASET ACTIVATE  subset.
DATASET COPY  temp1.
DATASET ACTIVATE  temp1.
FILTER OFF.
USE ALL.
SELECT IF (hurende_huishoudens > 0).
EXECUTE.
rename variables hurende_huishoudens = kubus2210_woongelegenheden.
compute v2210_eigenaar_huurder=2.

* dan de eigenaars.
DATASET ACTIVATE  subset.
DATASET COPY  temp2.
DATASET ACTIVATE  temp2.
FILTER OFF.
USE ALL.
SELECT IF (inwonend_eigenaarsgezin > 0).
EXECUTE.
rename variables inwonend_eigenaarsgezin= kubus2210_woongelegenheden.
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
rename variables stat_sector=geoitem.
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


SAVE TRANSLATE OUTFILE=datamap + 'upload\kubus_woongelegenheden_' + datajaar + '.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/replace.

