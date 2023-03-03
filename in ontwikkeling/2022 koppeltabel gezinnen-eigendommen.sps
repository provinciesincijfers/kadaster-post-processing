* Encoding: windows-1252.



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

DEFINE datamap () 'h:\data\kadaster\' !ENDDEFINE.

* er is telkens maar één rij per eigendom.
GET
  FILE=datamap+ 'werkbestanden\eigendom_2022.sav'.
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
  /FILE=datamap + "2022\KAD_2022_eigendom_adres.txt"
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
  /FILE=datamap + "2022\KAD_2022_crabadres_rradres.txt"
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
  SAS DATA='H:\data\bevolking_naar_xy\bevolkingsdata\i_lhc_2022.sas7bdat'.
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
XSAVE outfile='C:\temp\manyrow.sav' /keep all. 
END LOOP. 
EXECUTE. 
GET file 'C:\temp\manyrow.sav'. 
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



SAVE OUTFILE=datamap + 'werkbestanden\koppelbevolking\alle_potentiele_koppelingen_gezinshoofd_eigendom.sav'
  /COMPRESSED.


dataset close bevolking.
dataset close huishoudens.
dataset close backupkoppeling.
dataset close eigadresbackup.


*GET
  FILE=datamap + 'werkbestanden\koppelbevolking\alle_potentiele_koppelingen_gezinshoofd_eigendom.sav'.
DATASET NAME eigadres WINDOW=FRONT.



* HIER OPSLAAN.



*** KLAARZETTEN EIGENAARS VAN EIGENAARSWONINGEN.

GET
  FILE=datamap + 'werkbestanden\eigendom_2021_basisafspraken.sav'.
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

dataset close eigendommen.

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
dataset close temp.

* enkel Belgische personen met een identificatie overhouden die minstens een eigenaarswoongelegenheid voor minstens 10% bezitten.
FILTER OFF.
USE ALL.
SELECT IF (identificatie ~='' & belgisch_eigenaar=1 & type_persoon="P" & woongelegenheden>0 & aandeel_eigendom>0.1 & eigenaar_huurder=1).
EXECUTE.


match files
/file=*
/keep=eigendom_id identificatie volgorde aandeel_eigendom.

rename variables identificatie=nationaal_nummer.
alter type nationaal_nummer (f8.0).

* er zijn enkele rare gevallen waar een mens twee keer eigenaar is van hetzelfde eigendom.
DATASET ACTIVATE eigenaars.
DATASET DECLARE aggreigenaars.
AGGREGATE
  /OUTFILE='aggreigenaars'
  /BREAK=eigendom_id nationaal_nummer 
  /volgorde=MIN(volgorde) 
  /aandeel_eigendom=SUM(aandeel_eigendom).




*** EINDE KLAARZETTEN EIGENAARS VAN EIGENAARSWONINGEN.


*** KOPPEL potentiele eigenaar/eigendom combo's aan de echte combinaties.

DATASET ACTIVATE eigadres.
FILTER OFF.
USE ALL.
SELECT IF (NATIONAAL_NUMMER > 0).
EXECUTE.

sort cases eigendom_id (a) nationaal_nummer (a).


DATASET ACTIVATE eigadres.
MATCH FILES /FILE=*
  /TABLE='aggreigenaars'
  /BY eigendom_id nationaal_nummer.
EXECUTE.

* voor de koppeling hebben we 2.227.53 potentiële inwonende eigenaars.
* na de koppeling hebben we nog maar 1.642.969 potentiele inwonende eigenaars.
* dat is nog zo zot niet, aangezien we heel vaak meerdere eigenaars hebben op één eigendom!.

dataset close aggreigenaars.
dataset close eigenaars.

* EINDE.

*** We kunnen nu alle potentiële koppelingen verwijderen voor de eigenaars die we met zekerheid aan één pand kunnen toekennen.
* identificeer de best passende rij voor de eigaars.
DATASET ACTIVATE eigadres.
* Identify Duplicate Cases.
SORT CASES BY NATIONAAL_NUMMER(A) aandeel_eigendom(D).
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
EXECUTE.

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=NATIONAAL_NUMMER
  /aandeel_eigendom_max=MAX(aandeel_eigendom).

compute behouden=1.
if aandeel_eigendom_max>0 & matchsequence>1 behouden=0.
EXECUTE.

* met deze filter kunnen we ongeveer 20% van alle combinaties wegnemen.
FILTER OFF.
USE ALL.
SELECT IF (behouden = 1).
EXECUTE.

*** einde weggooien foute rijen voor inwonende eigenaars.
* voor 2.47 miljoen huishoudens kunnen we nu een zekere keuze maken.

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=NATIONAAL_NUMMER
  /zekerheid=N.
variable labels zekerheid 'inverse van zekerheid'.
delete variables PrimaryFirst
PrimaryLast
MatchSequence behouden.



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
frequencies nn_toegekend.
sort cases eigendom_id (a).

* we hebben mensen een willekeurig volgnummer gegeven (id) en daarop gekoppeld in dit proces.
* we hebben hier geteld de hoeveelste keer een mens voorkomt.
* iedereen kan maar één keer voorkomen als "is de Nde keer deze mens en is de Nde keer dit volgnummer".
do if (eigendom_id~=lag(eigendom_id) | (eigendom_id=lag(eigendom_id) & adrescode=lag(adrescode))).
if missing(nn_toegekend) & id=matchsequence_1 nn_toegekend=1.
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


* volgende ronde.

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
huidig_bewoond
zekerheid.
EXECUTE.



AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=eigendom_id
  /toegekende_inwoners=N.


SAVE OUTFILE=datamap + 'werkbestanden\koppeltabel_rrgezinshoofd_eigendom_2022.sav'
  /COMPRESSED.

dataset close bevolking.
dataset close huishoudens.
dataset close backupkoppeling.



SAVE TRANSLATE OUTFILE=datamap + 'werkbestanden\koppeltabel_rrgezinshoofd_eigendom_2022.sas7bdat'
  /TYPE=SAS
  /VERSION=7
  /PLATFORM=WINDOWS
  /MAP
  /REPLACE.
