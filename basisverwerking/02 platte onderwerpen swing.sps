* Encoding: windows-1252.

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



* LUIK 4: aggregatie naar Swing.
compute LUIK4=$sysmis.
* platte onderwerpen.

*  met woongelegenheden in individuele woningen, appartementen en collectieven.
if type_woonaanbod=1 v2210_wa_indiv=woongelegenheden.
if type_woonaanbod=2 v2210_wa_app=woongelegenheden.
if type_woonaanbod=3 v2210_wa_coll=woongelegenheden.


* indicatoren eengezins/meergezinswoningen.
* al deze indicatoren kunnen eenvoudig opgeteld worden.
if eengezin_meergezin=1 v2210_wv_eengezinswoningen=woongelegenheden.
if eengezin_meergezin=2 v2210_wv_meergezinswoningen=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot <=5 v2210_wv_mg_2_5=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot > 5 & woongelegenheden_perceel_tot <=10 v2210_wv_mg_6_10=woongelegenheden.
if eengezin_meergezin=2 & woongelegenheden_perceel_tot >10 v2210_wv_mg_11p=woongelegenheden.

* strikt gezien niet nodig: teller aantal teruggevonden huishoudens.
compute v2210_huishoudens=huidig_bewoond.


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


* indicatoren laatste wijziging (enkel bij woongelegenheden, obv woonvoorraad).
* al deze indicatoren kunnen eenvoudig opgeteld worden.
if laatste_wijziging_cat_wgl=8 v2210_wv_lw_1983_1990=woongelegenheden.
if laatste_wijziging_cat_wgl=9 v2210_wv_lw_1991_2000=woongelegenheden.
if laatste_wijziging_cat_wgl=10 v2210_wv_lw_2001_2010=woongelegenheden.
if laatste_wijziging_cat_wgl=11 v2210_wv_lw_2011_2020=woongelegenheden.
if laatste_wijziging_cat_wgl=13 v2210_wv_lw_onbekend=woongelegenheden.


* platte onderwerpen recentste jaar.
if recentste_jaar>=1983 & recentste_jaar <= 1990 v2210_wgl_lwbj_1983_1990=woongelegenheden.
if recentste_jaar>=1991 & recentste_jaar <= 2000 v2210_wgl_lwbj_1991_2000=woongelegenheden.
if recentste_jaar>=2001 & recentste_jaar <= 2010 v2210_wgl_lwbj_2001_2010=woongelegenheden.
if recentste_jaar>=2011 & recentste_jaar <= 2020 v2210_wgl_lwbj_2011_2020=woongelegenheden.
*if recentste_jaar>=2021 & recentste_jaar <= 1990 v2210_wgl_lwbj_2021_2030=woongelegenheden.
if recentste_jaar>=1983 v2210_wgl_lwbj_1983p=woongelegenheden.


*voorbereiding.
rename variables stat_sector=geoitem.

DATASET DECLARE aggr.
AGGREGATE
  /OUTFILE='aggr'
  /BREAK=geoitem
/v2210_woonvoorraad=sum(woongelegenheden)
/v2210_woonaanbod=sum(wgl_woonfunctie)
/v2210_wa_indiv=sum(v2210_wa_indiv)
/v2210_wa_app=sum(v2210_wa_app)
/v2210_wa_coll=sum(v2210_wa_coll)
/v2210_wv_eengezinswoningen=sum(v2210_wv_eengezinswoningen)
/v2210_wv_meergezinswoningen=sum(v2210_wv_meergezinswoningen)
/v2210_wv_mg_2_5=sum(v2210_wv_mg_2_5)
/v2210_wv_mg_6_10=sum(v2210_wv_mg_6_10)
/v2210_wv_mg_11p=sum(v2210_wv_mg_11p)
/v2210_huishoudens=sum(v2210_huishoudens)
/v2210_huurders=sum(hurende_huishoudens)
/v2210_inwonend_eigenaarsgezin=sum(inwonend_eigenaarsgezin)
/v2210_hh_onbekend=sum(bewoning_zonder_link)
/v2210_wv_bj_voor1900=sum(v2210_wv_bj_voor1900)
/v2210_wv_bj_1900_1918=sum(v2210_wv_bj_1900_1918)
/v2210_wv_bj_1919_1930=sum(v2210_wv_bj_1919_1930)
/v2210_wv_bj_1931_1945=sum(v2210_wv_bj_1931_1945)
/v2210_wv_bj_1946_1960=sum(v2210_wv_bj_1946_1960)
/v2210_wv_bj_1961_1970=sum(v2210_wv_bj_1961_1970)
/v2210_wv_bj_1971_1980=sum(v2210_wv_bj_1971_1980)
/v2210_wv_bj_1981_1990=sum(v2210_wv_bj_1981_1990)
/v2210_wv_bj_1991_2000=sum(v2210_wv_bj_1991_2000)
/v2210_wv_bj_2001_2010=sum(v2210_wv_bj_2001_2010)
/v2210_wv_bj_2011_2020=sum(v2210_wv_bj_2011_2020)
/v2210_wv_bj_onbekend=sum(v2210_wv_bj_onbekend)
/v2210_wv_lw_1983_1990=sum(v2210_wv_lw_1983_1990)
/v2210_wv_lw_1991_2000=sum(v2210_wv_lw_1991_2000)
/v2210_wv_lw_2001_2010=sum(v2210_wv_lw_2001_2010)
/v2210_wv_lw_2011_2020=sum(v2210_wv_lw_2011_2020)
/v2210_wv_lw_onbekend=sum(v2210_wv_lw_onbekend)
/v2210_wgl_lwbj_1983_1990=sum(v2210_wgl_lwbj_1983_1990)
/v2210_wgl_lwbj_1991_2000=sum(v2210_wgl_lwbj_1991_2000)
/v2210_wgl_lwbj_2001_2010=sum(v2210_wgl_lwbj_2001_2010)
/v2210_wgl_lwbj_2011_2020=sum(v2210_wgl_lwbj_2011_2020)
/v2210_wgl_lwbj_1983p=sum(v2210_wgl_lwbj_1983p)
/v2210_open=sum(egw_open_bouwvorm)
/v2210_halfopen=sum(egw_halfopen_bouwvorm)
/v2210_gesloten=sum(egw_gesloten_bouwvorm)
/v2210_egw_andere=sum(egw_andere_bouwvorm).


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
v2210_hh_onbekend
v2210_wv_bj_voor1900
v2210_wv_bj_1900_1918
v2210_wv_bj_1919_1930
v2210_wv_bj_1931_1945
v2210_wv_bj_1946_1960
v2210_wv_bj_1961_1970
v2210_wv_bj_1971_1980
v2210_wv_bj_1981_1990
v2210_wv_bj_1991_2000
v2210_wv_bj_2001_2010
v2210_wv_bj_2011_2020
v2210_wv_bj_onbekend
v2210_wv_lw_1983_1990
v2210_wv_lw_1991_2000
v2210_wv_lw_2001_2010
v2210_wv_lw_2011_2020
v2210_wv_lw_onbekend
v2210_wgl_lwbj_1983_1990
v2210_wgl_lwbj_1991_2000
v2210_wgl_lwbj_2001_2010
v2210_wgl_lwbj_2011_2020
v2210_wgl_lwbj_1983p 
v2210_open
v2210_halfopen
v2210_gesloten
v2210_egw_andere (f8.0).


* regel1: indien gebied onbekend: enkel dingen inlezen indien nodig. Alle zinloze waarden vervangen we door -99996.
* regel 2: indien Brussel: ALLES is een brekende missings -99999 (TOGA).
* regel 3: indien in een niet-onbekende statsec (alles behalve iets met "zzzz" is 0 = 0 en ook missing=0.

* regel 1.
do if char.index(geoitem,"ZZZZ")>0.
recode v2210_woonvoorraad v2210_woonaanbod v2210_wa_indiv v2210_wa_app
v2210_wa_coll v2210_wv_eengezinswoningen v2210_wv_meergezinswoningen v2210_wv_mg_2_5
v2210_wv_mg_6_10 v2210_wv_mg_11p v2210_huishoudens v2210_huurders
v2210_inwonend_eigenaarsgezin v2210_hh_onbekend v2210_wv_bj_voor1900 v2210_wv_bj_1900_1918
v2210_wv_bj_1919_1930 v2210_wv_bj_1931_1945 v2210_wv_bj_1946_1960 v2210_wv_bj_1961_1970
v2210_wv_bj_1971_1980 v2210_wv_bj_1981_1990 v2210_wv_bj_1991_2000 v2210_wv_bj_2001_2010
v2210_wv_bj_2011_2020 v2210_wv_bj_onbekend v2210_wv_lw_1983_1990 v2210_wv_lw_1991_2000
v2210_wv_lw_2001_2010 v2210_wv_lw_2011_2020 v2210_wv_lw_onbekend v2210_wgl_lwbj_1983_1990
v2210_wgl_lwbj_1991_2000 v2210_wgl_lwbj_2001_2010 v2210_wgl_lwbj_2011_2020 v2210_wgl_lwbj_1983p v2210_open
v2210_halfopen v2210_gesloten v2210_egw_andere
(0=-99996) (missing=-99996).
end if.

* regel 2.
do if gewest=4000.
recode v2210_woonvoorraad v2210_woonaanbod v2210_wa_indiv v2210_wa_app
v2210_wa_coll v2210_wv_eengezinswoningen v2210_wv_meergezinswoningen v2210_wv_mg_2_5
v2210_wv_mg_6_10 v2210_wv_mg_11p v2210_huishoudens v2210_huurders
v2210_inwonend_eigenaarsgezin v2210_hh_onbekend v2210_wv_bj_voor1900 v2210_wv_bj_1900_1918
v2210_wv_bj_1919_1930 v2210_wv_bj_1931_1945 v2210_wv_bj_1946_1960 v2210_wv_bj_1961_1970
v2210_wv_bj_1971_1980 v2210_wv_bj_1981_1990 v2210_wv_bj_1991_2000 v2210_wv_bj_2001_2010
v2210_wv_bj_2011_2020 v2210_wv_bj_onbekend v2210_wv_lw_1983_1990 v2210_wv_lw_1991_2000
v2210_wv_lw_2001_2010 v2210_wv_lw_2011_2020 v2210_wv_lw_onbekend v2210_wgl_lwbj_1983_1990
v2210_wgl_lwbj_1991_2000 v2210_wgl_lwbj_2001_2010 v2210_wgl_lwbj_2011_2020 v2210_wgl_lwbj_1983p
v2210_open v2210_halfopen v2210_gesloten v2210_egw_andere
(else=-99999).
end if.

* regel 3.
do if gewest=2000 & char.index(geoitem,"ZZZZ")=0 .
recode v2210_woonvoorraad v2210_woonaanbod v2210_wa_indiv v2210_wa_app
v2210_wa_coll v2210_wv_eengezinswoningen v2210_wv_meergezinswoningen v2210_wv_mg_2_5
v2210_wv_mg_6_10 v2210_wv_mg_11p v2210_huishoudens v2210_huurders
v2210_inwonend_eigenaarsgezin v2210_hh_onbekend v2210_wv_bj_voor1900 v2210_wv_bj_1900_1918
v2210_wv_bj_1919_1930 v2210_wv_bj_1931_1945 v2210_wv_bj_1946_1960 v2210_wv_bj_1961_1970
v2210_wv_bj_1971_1980 v2210_wv_bj_1981_1990 v2210_wv_bj_1991_2000 v2210_wv_bj_2001_2010
v2210_wv_bj_2011_2020 v2210_wv_bj_onbekend v2210_wv_lw_1983_1990 v2210_wv_lw_1991_2000
v2210_wv_lw_2001_2010 v2210_wv_lw_2011_2020 v2210_wv_lw_onbekend v2210_wgl_lwbj_1983_1990
v2210_wgl_lwbj_1991_2000 v2210_wgl_lwbj_2001_2010 v2210_wgl_lwbj_2011_2020 v2210_wgl_lwbj_1983p
v2210_open v2210_halfopen v2210_gesloten v2210_egw_andere
(missing=0).
end if.

EXECUTE.
delete variables gewest.

* opmerking: na toepassen van deze regel zou het onmogelijk moeten zijn dat er nog velden zijn met een sysmis.

SAVE TRANSLATE OUTFILE=datamap + 'upload\pinc_basis_plat_' + datajaar + '.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/replace.
