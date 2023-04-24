* Encoding: windows-1252.


* map met alle kadasterdata.
DEFINE datamap () 'H:\data\kadaster\' !ENDDEFINE.
* dit gaat ervan uit dat je een map "upload" hebt in deze map.

* map met alle data die van Github komt.
DEFINE github () 'C:\github\' !ENDDEFINE.
* je hebt met name de repository "gebiedsniveaus" nodig.

* jaartal waarvoor we werken.
DEFINE datajaar () '2022' !ENDDEFINE.


GET
  FILE=datamap +  'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sav'.
DATASET NAME eigendommen WINDOW=FRONT.


if nis_indeling='1A' v2210_lgb_1AE=surface_total.
if nis_indeling='1B' v2210_lgb_1BC=surface_total.
if nis_indeling='1C' v2210_lgb_1BC=surface_total.
if nis_indeling='1D' v2210_lgb_1DI=surface_total.
if nis_indeling='1E' v2210_lgb_1AE=surface_total.
if nis_indeling='1F' v2210_lgb_1F=surface_total.
if nis_indeling='1G' v2210_lgb_1G=surface_total.
if nis_indeling='1H' v2210_lgb_1H=surface_total.
if nis_indeling='1I' v2210_lgb_1DI=surface_total.
if nis_indeling='1J' v2210_lgb_1J=surface_total.
if nis_indeling='1K' v2210_lgb_1K=surface_total.
if nis_indeling='1L' v2210_lgb_1L=surface_total.
if nis_indeling='1M' v2210_lgb_1MNOP=surface_total.
if nis_indeling='1N' v2210_lgb_1MNOP=surface_total.
if nis_indeling='1O' v2210_lgb_1MNOP=surface_total.
if nis_indeling='1P' v2210_lgb_1MNOP=surface_total.
if nis_indeling='2A1' v2210_lgb_2A1A2=surface_total.
if nis_indeling='2A2' v2210_lgb_2A1A2=surface_total.
if nis_indeling='2B' v2210_lgb_2B=surface_total.
if nis_indeling='2C' v2210_lgb_2C=surface_total.
if nis_indeling='2D' v2210_lgb_2DEF=surface_total.
if nis_indeling='2E' v2210_lgb_2DEF=surface_total.
if nis_indeling='2F' v2210_lgb_2DEF=surface_total.
if nis_indeling='2G' v2210_lgb_2G=surface_total.
if nis_indeling='2H' v2210_lgb_2H=surface_total.
if nis_indeling='2I' v2210_lgb_2I=surface_total.
if nis_indeling='2J' v2210_lgb_2JK=surface_total.
if nis_indeling='2K' v2210_lgb_2JK=surface_total.
if nis_indeling='2L' v2210_lgb_2L=surface_total.
if nis_indeling='2M' v2210_lgb_2M=surface_total.
if nis_indeling='2N' v2210_lgb_2N=surface_total.
if nis_indeling='2O' v2210_lgb_2O=surface_total.
if nis_indeling='2P' v2210_lgb_2P=surface_total.
if nis_indeling='2Q' v2210_lgb_2Q=surface_total.
if nis_indeling='2R' v2210_lgb_2RST=surface_total.
if nis_indeling='2S' v2210_lgb_2RST=surface_total.
if nis_indeling='2T' v2210_lgb_2RST=surface_total.



rename variables stat_sector=geoitem.
rename variables jaartal=period.



DATASET ACTIVATE eigendommen.
DATASET DECLARE agg0.
AGGREGATE
  /OUTFILE='agg0'
  /BREAK=period capakey geoitem
  /aard=first(aard)
 /woonfunctie=first(woonfunctie)
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
/v2210_wgl_opp=sum(v2210_wgl_opp)
/v2210_lgb_1AE=sum(v2210_lgb_1AE)
/v2210_lgb_1BC=sum(v2210_lgb_1BC)
/v2210_lgb_1DI=sum(v2210_lgb_1DI)
/v2210_lgb_1F=sum(v2210_lgb_1F)
/v2210_lgb_1G=sum(v2210_lgb_1G)
/v2210_lgb_1H=sum(v2210_lgb_1H)
/v2210_lgb_1J=sum(v2210_lgb_1J)
/v2210_lgb_1K=sum(v2210_lgb_1K)
/v2210_lgb_1L=sum(v2210_lgb_1L)
/v2210_lgb_1MNOP=sum(v2210_lgb_1MNOP)
/v2210_lgb_2A1A2=sum(v2210_lgb_2A1A2)
/v2210_lgb_2B=sum(v2210_lgb_2B)
/v2210_lgb_2C=sum(v2210_lgb_2C)
/v2210_lgb_2DEF=sum(v2210_lgb_2DEF)
/v2210_lgb_2G=sum(v2210_lgb_2G)
/v2210_lgb_2H=sum(v2210_lgb_2H)
/v2210_lgb_2I=sum(v2210_lgb_2I)
/v2210_lgb_2JK=sum(v2210_lgb_2JK)
/v2210_lgb_2L=sum(v2210_lgb_2L)
/v2210_lgb_2M=sum(v2210_lgb_2M)
/v2210_lgb_2N=sum(v2210_lgb_2N)
/v2210_lgb_2O=sum(v2210_lgb_2O)
/v2210_lgb_2P=sum(v2210_lgb_2P)
/v2210_lgb_2Q=sum(v2210_lgb_2Q)
/v2210_lgb_2RST=sum(v2210_lgb_2RST).
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
v2210_lgb_1AE
v2210_lgb_1BC
v2210_lgb_1DI
v2210_lgb_1F
v2210_lgb_1G
v2210_lgb_1H
v2210_lgb_1J
v2210_lgb_1K
v2210_lgb_1L
v2210_lgb_1MNOP
v2210_lgb_2A1A2
v2210_lgb_2B
v2210_lgb_2C
v2210_lgb_2DEF
v2210_lgb_2G
v2210_lgb_2H
v2210_lgb_2I
v2210_lgb_2JK
v2210_lgb_2L
v2210_lgb_2M
v2210_lgb_2N
v2210_lgb_2O
v2210_lgb_2P
v2210_lgb_2Q
v2210_lgb_2RST
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
v2210_lgb_1AE
v2210_lgb_1BC
v2210_lgb_1DI
v2210_lgb_1F
v2210_lgb_1G
v2210_lgb_1H
v2210_lgb_1J
v2210_lgb_1K
v2210_lgb_1L
v2210_lgb_1MNOP
v2210_lgb_2A1A2
v2210_lgb_2B
v2210_lgb_2C
v2210_lgb_2DEF
v2210_lgb_2G
v2210_lgb_2H
v2210_lgb_2I
v2210_lgb_2JK
v2210_lgb_2L
v2210_lgb_2M
v2210_lgb_2N
v2210_lgb_2O
v2210_lgb_2P
v2210_lgb_2Q
v2210_lgb_2RST
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
v2210_lgb_1AE
v2210_lgb_1BC
v2210_lgb_1DI
v2210_lgb_1F
v2210_lgb_1G
v2210_lgb_1H
v2210_lgb_1J
v2210_lgb_1K
v2210_lgb_1L
v2210_lgb_1MNOP
v2210_lgb_2A1A2
v2210_lgb_2B
v2210_lgb_2C
v2210_lgb_2DEF
v2210_lgb_2G
v2210_lgb_2H
v2210_lgb_2I
v2210_lgb_2JK
v2210_lgb_2L
v2210_lgb_2M
v2210_lgb_2N
v2210_lgb_2O
v2210_lgb_2P
v2210_lgb_2Q
v2210_lgb_2RST
(missing=0).
end if.

EXECUTE.
delete variables gewest.



SAVE TRANSLATE OUTFILE=datamap + 'upload\oppervlakte_hoogte_kamers_lgb' + datajaar + '.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/replace.

