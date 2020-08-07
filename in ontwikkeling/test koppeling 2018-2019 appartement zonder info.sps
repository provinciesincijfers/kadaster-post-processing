* Encoding: windows-1252.
GET
  FILE='C:\temp\kadaster\werkbestanden\eigendom_2019.sav'.
DATASET NAME eigendommen2019 WINDOW=FRONT.

DATASET ACTIVATE eigendommen2019.
FILTER OFF.
USE ALL.
SELECT IF (aard = "APPARTEMENT #" & subtype_woning="" ).
EXECUTE.

match files
/file=*
/keep=capakey eigendom_id.
compute speciaal_geval=2019.

sort cases capakey (a) eigendom_id (a).

GET
  FILE='C:\temp\kadaster\werkbestanden\eigendom_2018.sav'.
DATASET NAME eigendommen2018 WINDOW=FRONT.
sort cases capakey (a) eigendom_id (a).


MATCH FILES /FILE=*
  /FILE='eigendommen2019'
  /BY capakey eigendom_id.
EXECUTE.

recode speciaal_geval (missing=2018).
recode jaartal (missing=2019).

