* Encoding: windows-1252.
* OPGELET: er is een harde compute period=2019 nodig vlak voor het aggregeren naar swing.

* hierin wordt ook oppervlakte, bouwlagen en woonkamers meegenomen (nog niet in productie 7/2023).

* map met alle kadasterdata (gewoonlijk E:\data\kadaster\).
DEFINE datamap () 'H:\data\kadaster\' !ENDDEFINE.
* dit gaat ervan uit dat je een map "upload" hebt in deze map.

* map met alle data die van Github komt.
DEFINE github () 'C:\github\' !ENDDEFINE.

* jaartal waarvoor we werken.
DEFINE datajaar () '2022' !ENDDEFINE.


GET
  FILE=datamap +  'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

* weg te werken upstream.b
rename variables period=jaartal.
rename variables geoitem=stat_sector.

* LUIK 4: aggregatie naar Swing kubus.
compute LUIK4=$sysmis.



* we werken met WOONGELEGENHEDEN!

* en course de route hebben we al enkele variabelen gemaakt die rechtsreeks gebruikt kunnen worden als dimensieniveau.
* we hernoemen ze hier volgens de conventies voor kubusdimensieniveaus.
rename variables woonfunctie=v2210_woonfunctie.
rename variables bouwjaar_cat=v2210_bouwjaar_cat.
rename variables laatste_wijziging_cat=v2210_laatste_wijziging_cat.
rename variables eengezin_meergezin=v2210_eengezin_meergezin.



* aangepaste dimensie nav vergadering 20201016.
compute v2210_bouwvorm=0.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Open bebouwing" v2210_bouwvorm = 1.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Halfopen bebouwing" v2210_bouwvorm = 2.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Gesloten bebouwing" v2210_bouwvorm = 3.
if v2210_eengezin_meergezin=2 v2210_bouwvorm = 4.


* aangepaste dimensie nav issue 12. 
compute v2210_woningtype_bouwvorm=$sysmis.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Open bebouwing" v2210_woningtype_bouwvorm = 1.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Halfopen bebouwing" v2210_woningtype_bouwvorm = 2.
if v2210_eengezin_meergezin=1 & soort_bebouwing="Gesloten bebouwing" v2210_woningtype_bouwvorm = 3.
if v2210_eengezin_meergezin=1 & missing(v2210_woningtype_bouwvorm) v2210_woningtype_bouwvorm = 4.
if v2210_eengezin_meergezin=2 & woongelegenheden_perceel_tot<=5 v2210_woningtype_bouwvorm = 5.
if v2210_eengezin_meergezin=2 & woongelegenheden_perceel_tot>5 & woongelegenheden_perceel_tot<=10 v2210_woningtype_bouwvorm = 6.
if v2210_eengezin_meergezin=2 & woongelegenheden_perceel_tot>10 v2210_woningtype_bouwvorm = 7.
freq v2210_woningtype_bouwvorm.

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
v2210_woonfunctie v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_woningtype_bouwvorm ki inkomen
verdiep verdiepen_perceel 
v2210_aantal_kamers kamers_per_woning v2210_wgl_met_kamers v2210_woning_met_kamers
v2210_woonoppervlakte v2210_wooneenheid_opp v2210_wgl_opp.
EXECUTE.

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
dataset close subset.

* einde de-aggregatie.

* aanmaken variabele om de de-aggregatie duidelijk aan te tonen.
sort cases eigendom_id (a).
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=eigendom_id
  /deaggregatieteller=N.

* dimensie oppervlakte.
compute opp_per_wgl=v2210_woonoppervlakte/v2210_wgl_opp.
* antwerp style recode opp_per_wgl (lowest thru 60 = 1)
(60 thru 80 = 2)
(80 thru 100 = 3)
(100 thru 120 = 4)
(120 thru 140 = 5)
(140 thru 160 = 6)
(160 thru highest = 7) into v2210_opp_per_wgl.

recode opp_per_wgl  (lowest thru 59.999 = 1)
(60 thru 79.999 = 2)
(80 thru 99.999 = 3)
(100 thru 119.999 = 4)
(120 thru 159.999 = 5)
(160 thru 199.999 = 6)
(200 thru 249.999 = 7)
(250 thru highest = 8) (missing=0) into v2210_opp_per_wgl.
* ondergrens is > dan bovengrens <=.


* dimensie kamers.
recode kamers_per_woning
(lowest thru 2.999 = 1)
(3 thru 3.999 = 2)
(4 thru 4.999 = 3)
(5 thru 5.999 = 4)
(6 thru 6.999 = 5)
(7 thru highest = 6)
 (missing=0) into v2210_kamers_per_wgl.

* bouwlagen.
compute bouwlagen = verdiepen_inc_dakverdiep+1.
recode bouwlagen
(lowest thru 1 = 1)
(2 thru 2 = 2)
(2 thru 3 = 3)
(3 thru 4 = 4)
(4 thru 6 = 5)
(6 thru 9 = 6)
(9 thru 30 = 7)
(30 thru highest = 0)
 (missing=0) into v2210_bouwlagen.

* KUBUS WOONGELEGENHEDEN.






* verwerking op statsec.
string geolevel (a15).
compute geolevel="statsec".
rename variables stat_sector=geoitem.
RENAME VARIABLES jaartal=period.




DATASET DECLARE kubus1.
AGGREGATE
  /OUTFILE='kubus1'
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_eigenaar_huurder v2210_bouwjaar_cat v2210_woningtype_bouwvorm v2210_opp_per_wgl v2210_kamers_per_wgl v2210_bouwlagen
  /kubus2210_woongelegenheden=SUM(kubus2210_woongelegenheden).

* we voegen ook een verwerking op gemeenteniveau toe - strikt gezien niet nodig, maar helpt Swing vlotter werken.
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
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_eigenaar_huurder v2210_bouwjaar_cat v2210_woningtype_bouwvorm v2210_opp_per_wgl v2210_kamers_per_wgl v2210_bouwlagen
  /kubus2210_woongelegenheden=SUM(kubus2210_woongelegenheden).



DATASET ACTIVATE kubus1.
ADD FILES /FILE=*
  /FILE='kubus2'.
EXECUTE.

dataset close gemeente.
dataset close kubus2.
dataset close subset.

rename variables kubus2210_woongelegenheden = kubus2210_wgl_uitgebreid.


SAVE TRANSLATE OUTFILE=datamap + 'upload\kubus_woongelegenheden_' + datajaar + '_uitgebreid.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/replace.




* KUBUS KADASTRAAL INKOMEN.
dataset activate deaggregatie.
dataset close kubus1.
* KI voorbereiding.
string v2210_ki_bebouwd (a1).
compute v2210_ki_bebouwd=inkomen.
string v2210_ki_belast (a1).
compute v2210_ki_belast=CHAR.SUBSTR(inkomen,2,1).
compute kubus2210_ki=ki/woongelegenheden*kubus2210_woongelegenheden.

* codeboek zie https://share.vlaamsbrabant.be/share/page/site/socialeplanning/document-details?nodeRef=workspace://SpacesStore/aedcf0a5-9bb0-4e25-8979-00d8a82e753c
tabblad CodeCastralIncome.
* "gewoon gebouwd onroerend goed", itt ongebouwd, nijverheid, materieel.
recode  v2210_ki_bebouwd ("2"="1") (else="0").
recode  v2210_ki_belast ("F"="1") (else="0").
EXECUTE.


* verwerking op statsec.
DATASET DECLARE kubus1.
AGGREGATE
  /OUTFILE='kubus1'
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_eigenaar_huurder v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_woningtype_bouwvorm 
v2210_ki_bebouwd v2210_ki_belast
  /kubus2210_ki=SUM(kubus2210_ki).

* we voegen ook een verwerking op gemeenteniveau toe - strikt gezien niet nodig, maar helpt Swing vlotter werken.
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
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_eigenaar_huurder v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_woningtype_bouwvorm
  v2210_ki_bebouwd v2210_ki_belast
  /kubus2210_ki=SUM(kubus2210_ki).



DATASET ACTIVATE kubus1.
ADD FILES /FILE=*
  /FILE='kubus2'.
EXECUTE.

dataset close gemeente.
dataset close kubus2.

SAVE TRANSLATE OUTFILE=datamap + 'upload\kubus_ki_' + datajaar + '.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/replace.


* KI van enkel de gewone bebouwde percelen.
dataset activate deaggregatie.
FILTER OFF.
USE ALL.
SELECT IF (v2210_ki_bebouwd = "1" & v2210_ki_belast = "1").
EXECUTE.
* verwerking op statsec.
DATASET DECLARE kubus1.
AGGREGATE
  /OUTFILE='kubus1'
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_eigenaar_huurder v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_woningtype_bouwvorm 
  /kubus2210_ki_bebouwdbelast=SUM(kubus2210_ki).

* we voegen ook een verwerking op gemeenteniveau toe - strikt gezien niet nodig, maar helpt Swing vlotter werken.
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
  /BREAK=period geolevel geoitem v2210_woonfunctie v2210_eigenaar_huurder v2210_bouwjaar_cat v2210_laatste_wijziging_cat v2210_woningtype_bouwvorm
  /kubus2210_ki_bebouwdbelast=SUM(kubus2210_ki_bebouwdbelast).



DATASET ACTIVATE kubus1.
ADD FILES /FILE=*
  /FILE='kubus2'.
EXECUTE.

dataset close gemeente.
dataset close kubus2.

SAVE TRANSLATE OUTFILE=datamap + 'upload\kubus_ki_bebouwdbelast_' + datajaar + '.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/replace.



dataset close deaggregatie.




