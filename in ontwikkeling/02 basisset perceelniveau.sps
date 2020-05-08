* Encoding: windows-1252.

GET
  FILE='C:\temp\kadaster\eigendommen.sav'.
DATASET NAME eigendommen WINDOW=FRONT.
alter type capakey (a17).
* woningen tellen.
if bewoonbaar="N" niet_bewoonbare_wooneenheden=wooneenheden.
if bewoonbaar="J" & wooneenheden = 0 bewoonbaar_zonder_wooneenheid=1.
if bewoonbaar="J" bewoonbare_wooneenheden=wooneenheden.
recode niet_bewoonbare_wooneenheden
bewoonbaar_zonder_wooneenheid
bewoonbare_wooneenheden (missing=0).

* INDICATOR wooneenheden (versie ruime inschatting).
compute wooneenheden_kadaster = bewoonbaar_zonder_wooneenheid+bewoonbare_wooneenheden.
*** verder onderzoeken om te kiezen.

* INDICATOR gecorrigeerde wooneenheden.
compute wooneenheden_gecorrigeerd=max(bewoonbare_wooneenheden,huidig_bewoond).
EXECUTE.


* bewoond of niet?.
recode huidig_bewoond (missing=0) (0=0) (1 thru highest=1) into bewoond_onbewoond.
value labels bewoond_onbewoond
0 'niet bewoond'
1 'wel bewoond'.

* classificering van eigendommen naar eigenaars volgens type.
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
** omvat alle woningen in verhuurde eigendommen.
if eigenaar_huurder = 2 hh_verhuurde_wooneenheden=huidig_bewoond.
** MAAR OOK extra woningen in eigendommen met inwonende eigenaars.
if eigenaar_huurder = 1 & huidig_bewoond > 1 hh_verhuurde_wooneenheden = huidig_bewoond - 1.

* huishoudens eigenaarswoningen (de fout is kleiner als er slechts één inwonend gezin is op een eigendom).
if eigenaar_huurder = 1 hh_eigenaarswoningen=1.
EXECUTE.



GET
  FILE='C:\temp\kadaster\koppeling.sav'.
DATASET NAME koppeling WINDOW=FRONT.
DATASET ACTIVATE koppeling.
alter type capakey (a17).
DATASET DECLARE statsec.
AGGREGATE
  /OUTFILE='statsec'
  /BREAK=capakey stat_sector
  /N_BREAK=N.
dataset activate statsec.
delete variables n_break.

dataset activate eigendommen.
sort cases capakey (a).
dataset close koppeling.




DATASET ACTIVATE eigendommen.
MATCH FILES /FILE=*
  /TABLE='statsec'
  /BY capakey.
EXECUTE.



* afhandelen onbekende statsec.
STRING  capa5 (A5).
COMPUTE capa5=capakey.
EXECUTE.

GET
  FILE='C:\temp\kadaster\x_capa5_niscode.sav'.
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






* VOOR PERCELEN.

string aard_all (a300).
sort cases capakey (a) aard (a).
if $casenum=1 | capakey~=lag(capakey) aard_all=ltrim(rtrim(aard)).
if capakey=lag(capakey) & aard=lag(aard) aard_all=ltrim(rtrim(lag(aard))).
if capakey=lag(capakey) & aard~=lag(aard) aard_all=concat(ltrim(rtrim(lag(aard_all))),",",ltrim(rtrim(aard))).
EXECUTE.
DATASET DECLARE aardall.
AGGREGATE
  /OUTFILE='aardall'
  /BREAK=capakey
  /aard_all=LAST(aard_all)
  /N_BREAK=N.

string bouwjaar_str (a4).
compute bouwjaar_str=string(bouwjaar,F4.0).
string bouwjaar_str_all (a100).
sort cases capakey (a) bouwjaar_str (a).
if $casenum=1 | capakey~=lag(capakey) bouwjaar_str_all=ltrim(rtrim(bouwjaar_str)).
if capakey=lag(capakey) & bouwjaar_str=lag(bouwjaar_str) bouwjaar_str_all=ltrim(rtrim(lag(bouwjaar_str))).
if capakey=lag(capakey) & bouwjaar_str~=lag(bouwjaar_str) bouwjaar_str_all=concat(ltrim(rtrim(lag(bouwjaar_str_all))),",",ltrim(rtrim(bouwjaar_str))).
DATASET DECLARE bouwjaar_strall.
AGGREGATE
  /OUTFILE='bouwjaar_strall'
  /BREAK=capakey
  /bouwjaar_str_all=LAST(bouwjaar_str_all)
  /N_BREAK=N.


AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /verdieping_max=MAX(verdieping) 
  /bovengrondse_verdiepingen_max=MAX(bovengrondse_verdiepingen).
compute max_verdiep=max(verdieping_max,bovengrondse_verdiepingen_max).

if huidig_bewoond>wooneenheden_kadaster overbewoond=huidig_bewoond-wooneenheden_kadaster.
if huidig_bewoond<wooneenheden_kadaster onderbewoond=wooneenheden_kadaster-huidig_bewoond.

recode hh_huur
hh_eig
hh_tot (missing=0).
compute hh_tot=hh_eigenaarswoningen+hh_verhuurde_wooneenheden.


DATASET ACTIVATE eigendommen.
DATASET DECLARE aggr.
AGGREGATE
  /OUTFILE='aggr'
  /BREAK=capakey stat_sector
  /straatnaam=first(straatnaam)
  /wo_corr=SUM(wooneenheden_gecorrigeerd)
  /wo_kad=SUM(wooneenheden_kadaster) 
  /hh_huur=SUM(hh_verhuurde_wooneenheden) 
  /hh_eig=SUM(hh_eigenaarswoningen)
  /hh_tot=SUM(hh_tot)
  /wijzmax=max(laatste_wijziging)
  /bouwjmax=max(bouwjaar)
  /bouwjmin=min(bouwjaar)
  /verdiepen=max(max_verdiep)
  /overwoon=sum(overbewoond)
  /onderwoon=sum(onderbewoond).
dataset activate aggr.


compute p_eig=hh_eig/hh_tot.



dataset activate aardall.
delete variables n_break.
DATASET ACTIVATE aggr.
MATCH FILES /FILE=*
  /TABLE='aardall'
  /BY capakey.
EXECUTE.
dataset close aardall.



dataset activate bouwjaar_strall.
delete variables n_break.
DATASET ACTIVATE aggr.
MATCH FILES /FILE=*
  /TABLE='bouwjaar_strall'
  /BY capakey.
EXECUTE.
dataset close bouwjaar_strall.

dataset activate eigendommen.
match files
/file=*
/keep=capakey ki aard bouwjaar laatste_wijziging soort_bebouwing
subtype_woning.
EXECUTE.

DATASET ACTIVATE eigendommen.
* Identify Duplicate Cases.
SORT CASES BY capakey(A) KI(A).
MATCH FILES
  /FILE=*
  /BY capakey
  /LAST=PrimaryLast.
VARIABLE LABELS  PrimaryLast 'Indicator of each last matching case as Primary'.
VALUE LABELS  PrimaryLast 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryLast (ORDINAL).
EXECUTE.

FILTER OFF.
USE ALL.
SELECT IF (PrimaryLast = 1).
EXECUTE.


GET TRANSLATE
  FILE='C:\temp\kadaster\geo\Adp_combi_origineel.dbf'
  /TYPE=DBF /MAP .
DATASET NAME attributen WINDOW=FRONT.
compute volgnummer=$casenum.
alter type capakey (a17).
sort cases capakey (a).
delete variables d_r.

MATCH FILES /FILE=*
  /TABLE='aggr'
  /BY capakey.
EXECUTE.
dataset close aggr.


dataset activate eigendommen.
alter type capakey (a17).
sort cases capakey (a).
delete variables ki primarylast.

dataset activate attributen.
MATCH FILES /FILE=*
  /TABLE='eigendommen'
  /BY capakey.
EXECUTE.
dataset close eigendommen.

rename variables bouwjaar_str_all = bouwjkim.
rename variables aard = aardkim.
delete variables bouwjaar laatste_wijziging.
rename variables soort_bebouwing = sbebkim.
rename variables subtype_woning = subtwkim.
rename variables stat_sector=statsec.

sort cases volgnummer (a).

SAVE TRANSLATE OUTFILE='C:\temp\kadaster\geo\Adp_combi.dbf'
  /TYPE=DBF
  /VERSION=4
  /MAP
  /REPLACE.

