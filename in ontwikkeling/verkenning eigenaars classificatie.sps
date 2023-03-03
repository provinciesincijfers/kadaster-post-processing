* Encoding: windows-1252.



GET
  FILE='h:\data\kadaster\werkbestanden\eigendom_2021_basisafspraken.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

* verzamel woningen en KI per eigendom.


* KI code overgenomen van kubus.
string v2210_ki_bebouwd (a1).
compute v2210_ki_bebouwd=inkomen.
string v2210_ki_belast (a1).
compute v2210_ki_belast=CHAR.SUBSTR(inkomen,2,1).
* codeboek zie https://share.vlaamsbrabant.be/share/page/site/socialeplanning/document-details?nodeRef=workspace://SpacesStore/aedcf0a5-9bb0-4e25-8979-00d8a82e753c
tabblad CodeCastralIncome.
* "gewoon gebouwd onroerend goed", itt ongebouwd, nijverheid, materieel.
recode  v2210_ki_bebouwd ("2"="1") (else="0").
recode  v2210_ki_belast ("F"="1") (else="0").
EXECUTE.
dataset copy temp.
dataset activate temp.
match files
/file=*
/keep=
eigendom_id
capakey
ki
v2210_ki_bebouwd
v2210_ki_belast
eigenaar_huurder
woongelegenheden.
sort cases eigendom_id (a).

DATASET ACTIVATE temp.
* verwijder bewoning zonder link.
FILTER OFF.
USE ALL.
SELECT IF (eigendom_id > 0).
EXECUTE.


* koppel aan eigenaars.

GET
  FILE='H:\data\kadaster\werkbestanden\basisafspraken_alle_eigenaars_2022.sav'.
DATASET NAME eigenaars WINDOW=FRONT.

* maak een eigenaarsclassificatie:
- hoeveel woningen in bezit
- hoeveel eigendommen met woningen in bezit
- hoeveel eigendommen in totaal in bezit
-> gemeten naar woningen, eigendommen, KI
-> rekening houden met % in bezit


DATASET ACTIVATE eigenaars.
sort cases eigendom_id (a).
MATCH FILES /FILE=*
  /TABLE='temp'
  /BY eigendom_id.
EXECUTE.

DATASET DECLARE tussenbestand. 
AGGREGATE 
  /OUTFILE='tussenbestand' 
  /BREAK=identificatie naam aandeel_eigendom type_persoon v2210_ki_bebouwd v2210_ki_belast 
    eigenaar_huurder 
  /KI_sum=SUM(KI) 
  /woongelegenheden_sum=SUM(woongelegenheden) 
  /N_BREAK=N.



DATASET ACTIVATE tussenbestand.
FILTER OFF.
USE ALL.
SELECT IF (identificatie ~='').
EXECUTE.

compute bezit_woongelegenheden=woongelegenheden_sum*aandeel_eigendom.

