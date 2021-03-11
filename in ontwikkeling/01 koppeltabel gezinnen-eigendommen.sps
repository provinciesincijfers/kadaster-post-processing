* Encoding: windows-1252.


* EERSTE GEFAALD OPZET.
* verzamel unieke gezinnen met ID
* koppel via rradres aan crabadres > massieve ontdubbeling!
* koppel crab aan eigendom > massieve ontdubbeling!
* kies aan welke eigendom je het uniek gezin toekent, op basis dat "elk gezin slechts eens toegekend wordt" 
EN "elke eigendom slechts het juiste aantal gezinnen heeft"

* TWEEDE GESLAAGD OPZET.
* vertrekken langs kant eigendommen.
* er is telkens maar één rij per eigendom.
* daar horen meerdere crab-adressen bij, 
* dus koppelen we de eigendommen aan die adressen.
* dezelfde eigendommen zitten hier dus nu meerdere keren in.
* we zijn niet geïnteresseerd in adressen waar geen bewoonde eigendom bij zou kunnen horen.
* vervolgens verrijken we de eigendom/crabadres combinatie met een rijksregisteradres.
* maar in de dataset crabadres-rradres kan hetzelfde crab-adres meerdere keren voorkomen.
* we moeten daarom de eigendom-crab data vermenigvuldigen om eerst ongeveer evenveel rijen te hebben.


* er is telkens maar één rij per eigendom.
GET
  FILE='C:\temp\kadaster\werkbestanden\eigendom_2019.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

* we zijn enkel geïnteresseerd in de bewoonde eigendommen.
DATASET ACTIVATE eigendommen.
FILTER OFF.
USE ALL.
SELECT IF (huidig_bewoond > 0).
EXECUTE.

match files
/file=*
/keep=eigendom_id huidig_bewoond.
EXECUTE.
sort cases eigendom_id (a).


* er horen echter meerdere crab adressen bij.
PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE="C:\temp\kadaster\2019\KAD_2019_eigendom_adres.txt"
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal 4X
  capakey A17
  eigendom_id F9.0
  straatnaamcode F6.0
  huisbis A26
  bepaald_via A8
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME eigadres WINDOW=FRONT.
sort cases eigendom_id (a).
delete variables provincie bepaald_via capakey.

* dus koppelen we de eigendommen aan die adressen.
* dezelfde eigendommen zitten hier dus nu meerdere keren in.
DATASET ACTIVATE eigadres.
MATCH FILES /FILE=*
  /TABLE='eigendommen'
  /BY eigendom_id.
EXECUTE.

* we zijn niet geïnteresseerd in adressen waar geen bewoonde eigendom bij zou kunnen horen.
FILTER OFF.
USE ALL.
SELECT IF (huidig_bewoond > 0).
EXECUTE.
dataset close eigendommen.

sort cases straatnaamcode (a) huisbis (a).

* vervolgens verrijken we de eigendom/crabadres combinatie met een rijksregisteradres.

PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE="C:\temp\kadaster\2019\KAD_2019_crabadres_rradres.txt"
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  straatnaamcode f6.0
  huisbis A26
  niscode F5.0
  adrescode A12
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME crabrr WINDOW=FRONT.
delete variables provincie jaartal.

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=adrescode
  /teller_adrescode=N.


DATASET DECLARE telcrab.
AGGREGATE
  /OUTFILE='telcrab'
  /BREAK=straatnaamcode huisbis
  /teller_crab=N.


* maar in de dataset crabadres-rradres kan hetzelfde crab-adres meerdere keren voorkomen.
* we moeten daarom de eigendom-crab data vermenigvuldigen om eerst ongeveer evenveel rijen te hebben.
* in de praktijk komt dit maar met een maximum van 3 voor, dus we kunnen dit met add cases oplossen.

DATASET ACTIVATE eigadres.
sort cases straatnaamcode (a) huisbis (a).
MATCH FILES /FILE=*
  /TABLE='telcrab'
  /BY straatnaamcode huisbis.
EXECUTE.
DATASET CLOSE telcrab.


DATASET ACTIVATE eigadres.
DATASET COPY  telcrab2.
DATASET ACTIVATE  telcrab2.
FILTER OFF.
USE ALL.
SELECT IF (teller_crab=2).
EXECUTE.
DATASET ACTIVATE  eigadres.
DATASET COPY  telcrab3a.
DATASET ACTIVATE  telcrab3a.
FILTER OFF.
USE ALL.
SELECT IF (teller_crab=3).
EXECUTE.
DATASET ACTIVATE  eigadres.
DATASET COPY  telcrab3b.
DATASET ACTIVATE  telcrab3b.
FILTER OFF.
USE ALL.
SELECT IF (teller_crab=3).
EXECUTE.


DATASET ACTIVATE eigadres.
ADD FILES /FILE=*
  /FILE='telcrab2'
  /FILE='telcrab3a'
  /FILE='telcrab3b'.
EXECUTE.
dataset close telcrab2.
dataset close telcrab3a.
dataset close telcrab3b.

* we hebben wel in beide bestanden eenzelfde volgnummer nodig om "uniek" te kunnen linken.
SORT CASES BY eigendom_id(A) straatnaamcode(A) huisbis(A).
MATCH FILES
  /FILE=*
  /BY eigendom_id straatnaamcode huisbis
  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
MATCH FILES
  /FILE=*
  /DROP=PrimaryFirst PrimaryLast.
EXECUTE.
recode matchsequence (0=1).
SORT CASES BY straatnaamcode(A) huisbis(A) matchsequence (a).

* volgnummer maken in crab-rr koppeltabel.
DATASET ACTIVATE crabrr.
SORT CASES BY straatnaamcode(A) huisbis(A).
MATCH FILES
  /FILE=*
  /BY straatnaamcode huisbis
  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
MATCH FILES
  /FILE=*
  /DROP=PrimaryFirst PrimaryLast.
EXECUTE.
recode matchsequence (0=1).

DATASET ACTIVATE crabrr.
SORT CASES BY straatnaamcode(A) huisbis(A) matchsequence (a).


DATASET ACTIVATE eigadres.
rename variables teller_crab=teller_crabrr.
MATCH FILES /FILE=*
  /TABLE='crabrr'
  /BY straatnaamcode huisbis MatchSequence .
EXECUTE.

dataset close crabrr.

DATASET ACTIVATE eigadres.
dataset name eigadresbackup.
DATASET DECLARE eigadres.
AGGREGATE
  /OUTFILE='eigadres'
  /BREAK=eigendom_id adrescode
  /huidig_bewoond=MAX(huidig_bewoond).
DATASET ACTIVATE eigadres.
alter type adrescode (f12.0).

* we hebben een goede verdeelsleutel nodig: hetzelfde adres kan bij meerdere eigendommen horen; we moeten de iegndommen "opvullen" op basis van het aantal huishoudens dat Ilse toekende.



* binnenhalen bevolking en vereenvoudigen.
GET 
  SAS DATA='C:\temp\overstroming\i_lhc2_2019.sas7bdat'
  /formats='C:\temp\overstroming\formout2.sas7bdat'.
DATASET NAME bevolking WINDOW=FRONT. 

DATASET copy huishoudens.
dataset activate huishoudens.
FILTER OFF.
USE ALL.
SELECT IF (refpers = "J").
EXECUTE.

match files
/file=*
/keep=ADRESCODE NATIONAAL_NUMMER.
compute privaat_hh=1.
EXECUTE.

* dit zijn onzinadressen die we toch niet kunnen koppelen.
FILTER OFF.
USE ALL.
SELECT IF (ADRESCODE ~= "" & ADRESCODE ~= "000000000000" & ADRESCODE ~= "000099990000").
EXECUTE.

alter type adrescode (f12.0).

DATASET ACTIVATE huishoudens.
DATASET DECLARE hhadres.
AGGREGATE
  /OUTFILE='hhadres'
  /BREAK=ADRESCODE
  /huishoudens=N.

DATASET ACTIVATE eigadres.
sort cases adrescode (a).
MATCH FILES /FILE=*
  /TABLE='hhadres'
  /BY ADRESCODE.
EXECUTE.
dataset close hhadres.

FILTER OFF.
USE ALL.
SELECT IF (huishoudens > 0).
EXECUTE.


* nu enkel nog in eigadres rijen bijmaken op basis van huishoudens, zodat elk huishouden aan elke combi kan gelinkt worden.
* volgnummer toekennen; idem dito in "huishoudens"

dataset activate eigadres.
DATASET COPY  teontdubbelen.
DATASET ACTIVATE  teontdubbelen.
FILTER OFF.
USE ALL.
SELECT IF (huishoudens > 1).
EXECUTE.

LOOP id=1 to 456. 
XSAVE outfile='C:\temp\kadaster\werkbestanden\temp\manyrow.sav' /keep all. 
END LOOP. 
EXECUTE. 
GET file 'C:\temp\kadaster\werkbestanden\temp\manyrow.sav'. 
DATASET NAME ontdubbeld WINDOW=FRONT.
SELECT IF (id <= huishoudens). 
EXECUTE.
dataset close teontdubbelen.

DATASET ACTIVATE eigadres.
SELECT IF (huishoudens =1).
compute id=1.
EXECUTE.

DATASET ACTIVATE eigadres.
ADD FILES /FILE=*
  /FILE='ontdubbeld'.
EXECUTE.
dataset close ontdubbeld.







DATASET ACTIVATE huishoudens.
* Identify Duplicate Cases.
SORT CASES BY ADRESCODE(A).
MATCH FILES
  /FILE=*
  /BY ADRESCODE
  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
MATCH FILES
  /FILE=*
  /DROP=PrimaryFirst PrimaryLast.
VARIABLE LABELS  MatchSequence 'Sequential count of matching cases'.
VARIABLE LEVEL  MatchSequence (SCALE).
EXECUTE.
recode matchsequence (0=1).
rename variables matchsequence=id.

sort cases adrescode (a) id (a).
dataset activate eigadres.
sort cases adrescode (a) id (a).
MATCH FILES /FILE=*
  /TABLE='huishoudens'
  /BY adrescode id.
EXECUTE.



SAVE OUTFILE='C:\temp\kadaster\werkbestanden\alle_potentiele_koppelingen_gezinshoofd_eigendom.sav'
  /COMPRESSED.


dataset copy backupkoppeling.


* HIER OPSLAAN.


DATASET ACTIVATE eigadres.
FILTER OFF.
USE ALL.
SELECT IF (NATIONAAL_NUMMER > 0).
EXECUTE.




* Identify Duplicate Cases.
SORT CASES BY NATIONAAL_NUMMER(A).
MATCH FILES
  /FILE=*
  /BY NATIONAAL_NUMMER
  /FIRST=PrimaryFirst_1
  /LAST=PrimaryLast_1.
DO IF (PrimaryFirst_1).
COMPUTE  MatchSequence_1=1-PrimaryLast_1.
ELSE.
COMPUTE  MatchSequence_1=MatchSequence_1+1.
END IF.
LEAVE  MatchSequence_1.
FORMATS  MatchSequence_1 (f7).
EXECUTE.

if matchsequence_1=0 nn_toegekend=1.
sort cases eigendom_id (a).

* we hebben mensen een willekeurig volgnummer gegeven (id) en daarop gekoppeld in dit proces.
* we hebben hier geteld de hoeveelste keer een mens voorkomt.
* iedereen kan maar één keer voorkomen als "is de Nde keer deze mens en is de Nde keer dit volgnummer".
do if (eigendom_id~=lag(eigendom_id) | (eigendom_id=lag(eigendom_id) & adrescode=lag(adrescode))).
if id=matchsequence_1 nn_toegekend=1.
end if.

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=NATIONAAL_NUMMER
  /nn_num2=N
  /nn_toegekend_max=max(nn_toegekend).

compute #teverwijderen=0.
if missing(nn_toegekend) & nn_toegekend_max=1 #teverwijderen=1.
SELECT IF (#teverwijderen = 0).
EXECUTE.


AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=eigendom_id
  /toegekende_inwoners=sum(nn_toegekend).

* indien iemand nog toegekend moet worden, maar potentieel in een eigendom toegekend zou worden
die al 'vol zit', gooi die er dan uit.
* OPMERKING: in enkele gevallen hebben we nu al "overbewoning geintroduceerd", en het is mogelijk dat we nu enkele mensen onterecht weggooien.
compute #teverwijderen=0.
if huidig_bewoond<=toegekende_inwoners & missing(nn_toegekend) #teverwijderen=1.
SELECT IF (#teverwijderen = 0).
EXECUTE.


delete variables PrimaryFirst_1
PrimaryLast_1
MatchSequence_1.

* Identify Duplicate Cases.
SORT CASES BY NATIONAAL_NUMMER(A).
MATCH FILES
  /FILE=*
  /BY NATIONAAL_NUMMER
  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
COMPUTE  InDupGrp=MatchSequence>0.
SORT CASES InDupGrp(D).
VARIABLE LABELS  PrimaryLast 'Indicator of each last matching case as Primary' MatchSequence 
    'Sequential count of matching cases'.
VALUE LABELS  PrimaryLast 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryLast (ORDINAL) /MatchSequence (SCALE).
EXECUTE.

sort cases eigendom_id (a) nn_toegekend (a).
if eigendom_id~=lag(eigendom_id) nn_toeken2=toegekende_inwoners.
EXECUTE.
* als je toevallig de eerste keer voorkomt in een eigendom waar nog plaats is, ken dan toe en verhoog de toe-ken-teller.
do if eigendom_id~=lag(eigendom_id) & primaryfirst = 1 & missing(nn_toegekend) & nn_toeken2<huidig_bewoond.
compute nn_toegekend=1.
compute nn_toeken2=nn_toeken2+1.
end if.
* bij de verdere rijen van de eigendommen kijken we opnieuw naar mensen die op die rij voor het eerst voorkomen.
do if eigendom_id=lag(eigendom_id) & primaryfirst = 1 & missing(nn_toegekend) & lag(nn_toeken2)<huidig_bewoond.
compute nn_toegekend=1.
compute nn_toeken2=lag(nn_toeken2)+1.
end if.
EXECUTE.

delete variables PrimaryFirst
PrimaryLast
MatchSequence
InDupGrp.

* opnieuw controleren wie reeds toegekend is.
delete variables nn_toegekend_max.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=NATIONAAL_NUMMER
  /nn_toegekend_max=max(nn_toegekend).

compute #teverwijderen=0.
if missing(nn_toegekend) & nn_toegekend_max=1 #teverwijderen=1.
SELECT IF (#teverwijderen = 0).
EXECUTE.

* opnieuw nagaan in welke eigendommen nog plaats is.
delete variables toegekende_inwoners.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=eigendom_id
  /toegekende_inwoners=sum(nn_toegekend).

* gooi mensen weg die je potentieel zou kunnen toekennen aan eigendommen die al vol zitten.
compute #teverwijderen=0.
if huidig_bewoond<=toegekende_inwoners & missing(nn_toegekend) #teverwijderen=1.
SELECT IF (#teverwijderen = 0).
EXECUTE.


* nog een keer opnieuw!.
SORT CASES BY NATIONAAL_NUMMER(A).
MATCH FILES
  /FILE=*
  /BY NATIONAAL_NUMMER
  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
COMPUTE  InDupGrp=MatchSequence>0.
SORT CASES InDupGrp(D).
VARIABLE LABELS  PrimaryLast 'Indicator of each last matching case as Primary' MatchSequence 
    'Sequential count of matching cases'.
VALUE LABELS  PrimaryLast 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryLast (ORDINAL) /MatchSequence (SCALE).
EXECUTE.

if primaryfirst=1 & huidig_bewoond > toegekende_inwoners nn_toegekend=1.
EXECUTE.



delete variables PrimaryFirst
PrimaryLast
MatchSequence
InDupGrp.

delete variables nn_toegekend_max.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=NATIONAAL_NUMMER
  /nn_toegekend_max=max(nn_toegekend).

compute #teverwijderen=0.
if missing(nn_toegekend) & nn_toegekend_max=1 #teverwijderen=1.
SELECT IF (#teverwijderen = 0).
EXECUTE.

delete variables toegekende_inwoners.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=eigendom_id
  /toegekende_inwoners=sum(nn_toegekend).
recode toegekende_inwoners (missing=0).

compute #teverwijderen=0.
if huidig_bewoond=toegekende_inwoners & missing(nn_toegekend) #teverwijderen=1.
SELECT IF (#teverwijderen = 0).
EXECUTE.


* Identify Duplicate Cases.
SORT CASES BY NATIONAAL_NUMMER(A).
MATCH FILES
  /FILE=*
  /BY NATIONAAL_NUMMER
  /FIRST=PrimaryFirst
  /LAST=PrimaryLast.
DO IF (PrimaryFirst).
COMPUTE  MatchSequence=1-PrimaryLast.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
COMPUTE  InDupGrp=MatchSequence>0.
SORT CASES InDupGrp(D).
VARIABLE LABELS  PrimaryLast 'Indicator of each last matching case as Primary' MatchSequence 
    'Sequential count of matching cases'.
VALUE LABELS  PrimaryLast 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryLast (ORDINAL) /MatchSequence (SCALE).
EXECUTE.

if indupgrp=1 & nationaal_nummer~=lag(nationaal_nummer) & huidig_bewoond>toegekende_inwoners nn_toegekend=1.
if indupgrp=1 & MatchSequence=2 & missing(lag(nn_toegekend)) &  huidig_bewoond>toegekende_inwoners nn_toegekend=1.
EXECUTE.



delete variables PrimaryFirst
PrimaryLast
MatchSequence
InDupGrp.

delete variables nn_toegekend_max.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=NATIONAAL_NUMMER
  /nn_toegekend_max=max(nn_toegekend).

compute #teverwijderen=0.
if missing(nn_toegekend) & nn_toegekend_max=1 #teverwijderen=1.
SELECT IF (#teverwijderen = 0).
EXECUTE.

delete variables toegekende_inwoners.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=eigendom_id
  /toegekende_inwoners=sum(nn_toegekend).
recode toegekende_inwoners (missing=0).

compute #teverwijderen=0.
if huidig_bewoond=toegekende_inwoners & missing(nn_toegekend) #teverwijderen=1.
SELECT IF (#teverwijderen = 0).
EXECUTE.


* enkele overblijvende gevallen.
AGGREGATE 
  /OUTFILE=* MODE=ADDVARIABLES 
  /BREAK=NATIONAAL_NUMMER 
  /nn_toegekend_sum2=SUM(nn_toegekend).
if missing(nn_toegekend) & missing(nn_toegekend_sum2) nn_toegekend=1.

match files
/file=*
/keep=eigendom_id
adrescode
NATIONAAL_NUMMER
huidig_bewoond.
EXECUTE.



AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=eigendom_id
  /toegekende_inwoners=N.


SAVE OUTFILE='C:\temp\kadaster\werkbestanden\koppeltabel_rrgezinshoofd_eigendom.sav'
  /COMPRESSED.

dataset close bevolking.
dataset close huishoudens.
dataset close backupkoppeling.

