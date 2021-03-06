* Encoding: windows-1252.


* EERSTE GEFAALD OPZET.
* verzamel unieke gezinnen met ID
* koppel via rradres aan crabadres > massieve ontdubbeling!
* koppel crab aan eigendom > massieve ontdubbeling!
* kies aan welke eigendom je het uniek gezin toekent, op basis dat "elk gezin slechts eens toegekend wordt" 
EN "elke eigendom slechts het juiste aantal gezinnen heeft"

* TWEEDE GESLAAGD OPZET.
* vertrekken langs kant eigendommen.
* er is telkens maar ��n rij per eigendom.
* daar horen meerdere crab-adressen bij, 
* dus koppelen we de eigendommen aan die adressen.
* dezelfde eigendommen zitten hier dus nu meerdere keren in.
* we zijn niet ge�nteresseerd in adressen waar geen bewoonde eigendom bij zou kunnen horen.
* vervolgens verrijken we de eigendom/crabadres combinatie met een rijksregisteradres.
* maar in de dataset crabadres-rradres kan hetzelfde crab-adres meerdere keren voorkomen.
* we moeten daarom de eigendom-crab data vermenigvuldigen om eerst ongeveer evenveel rijen te hebben.


* er is telkens maar ��n rij per eigendom.
GET
  FILE='C:\temp\kadaster\werkbestanden\eigendom_2019.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

* we zijn enkel ge�nteresseerd in de bewoonde eigendommen.
DATASET ACTIVATE eigendommen.
FILTER OFF.
USE ALL.
SELECT IF (huidig_bewoond > 0).
EXECUTE.

match files
/file=*
/keep=eigendom_id huidig_bewoond.
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

* we zijn niet ge�nteresseerd in adressen waar geen bewoonde eigendom bij zou kunnen horen.
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

DATASET ACTIVATE crabrr.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=adrescode
  /teller_adrescode=N.

DATASET ACTIVATE crabrr.
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
rename variables teller_crab=teller_crabrr.
SORT CASES BY straatnaamcode(A) huisbis(A) matchsequence (a).


DATASET ACTIVATE eigadres.
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


* nu enkel nog in eigadres rijen bijmaken op basis van huidig bewoond, zodat er uniek gelinkt kan worden aan de huishoudens.
* volgnummer toekennen; idem dito in "huishoudens"

dataset activate eigadres.
DATASET COPY  teontdubbelen.
DATASET ACTIVATE  teontdubbelen.
FILTER OFF.
USE ALL.
SELECT IF (huidig_bewoond > 1).
EXECUTE.

LOOP id=1 to 567. 
XSAVE outfile='C:\temp\kadaster\werkbestanden\temp\manyrow.sav' /keep all. 
END LOOP. 
EXECUTE. 
GET file 'C:\temp\kadaster\werkbestanden\temp\manyrow.sav'. 
DATASET NAME ontdubbeld WINDOW=FRONT.
SELECT IF (id LE huidig_bewoond). 
EXECUTE.

DATASET ACTIVATE eigadres.
SELECT IF (huidig_bewoond =1).
compute id=1.

DATASET ACTIVATE eigadres.
ADD FILES /FILE=*
  /FILE='ontdubbeld'.
EXECUTE.
dataset close ontdubbeld.
dataset close teontdubbelen.

ALTER TYPE adrescode (f12.0).
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
EXECUTE.
delete variables id.
rename variables matchsequence=id.
recode id (0=1).



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


FILTER OFF.
USE ALL.
SELECT IF (ADRESCODE ~= "" & ADRESCODE ~= "000000000000" & ADRESCODE ~= "000099990000").
EXECUTE.

alter type adrescode (f12.0).



DATASET ACTIVATE huishoudens.
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
EXECUTE.
rename variables matchsequence=id.
recode id (0=1).



DATASET ACTIVATE huishoudens.
sort cases adrescode (a) id (a).
dataset activate eigadres.
sort cases adrescode (a) id (a).
MATCH FILES /FILE=*
  /TABLE='huishoudens'
  /BY adrescode id.
EXECUTE.

** THE END.

** bekijken fouten.
* rijen waar geen huishouden gekoppeld kon worden aan een eigendom, zijn geen
 probleem INDIEN er aan die eigendom al het juiste aantal huishoudens zijn gekoppeld.
DATASET ACTIVATE eigadres.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=eigendom_id
  /privaat_hh_eig=SUM(privaat_hh).

compute te_verwijderen=0.
if missing(privaat_hh) & privaat_hh_eig=huidig_bewoond te_verwijderen=1.
EXECUTE.

FILTER OFF.
USE ALL.
SELECT IF (te_verwijderen = 0).
EXECUTE.


* DENKFOUT GEVONDEN:
** indien eigendom gekoppeld wordt aan twee adressen, dan wordt er plaats gemaakt voor 2* het aantal huidig_bewoon ipv ��n maal
** bijvoorbeeld

194436 heeft 90 huidig bewoond
194442 heeft 82 huidig bewoond

214012130031 heeft 77 huishoudens
214012130033 heeft 95 huishoudens

nu worden voor 194436 90 rijen voorzien voor adres 31 EN 90 rijen voor adres 33. Daardoor blijft eigendom 42 "onderbewoond".

194436	214012130031
194436	214012130033
194442	214012130033

correcter zou misschijn  zijn om voor 31 77 rijen in totaal te genereren, en voor 33 in totaal 95 rijen
nu wordt voor eigendom 
194436+214012130033 geteld van 1 tem 90
en voor
194442+214012130033 doorgeteld van 91 tem 172 (som van 90 en 82) 
hierdoor worden de huishoudens slechts ��n keer toegekend. 

* bestand met mismatch om verder te bestuderen.
DATASET DECLARE testbewoondeig.
AGGREGATE
  /OUTFILE='testbewoondeig'
  /BREAK=eigendom_id
  /huidig_bewoond_max=MAX(huidig_bewoond) 
  /privaat_hh_sum=SUM(privaat_hh) 
  /collectief_sum=SUM(collectief).

DATASET ACTIVATE testbewoondeig.
RECODE privaat_hh_sum collectief_sum (SYSMIS=0).
compute hh_tot=privaat_hh_sum+collectief_sum.

FILTER OFF.
USE ALL.
SELECT IF (huidig_bewoond_max ~= hh_tot).
EXECUTE.


SAVE TRANSLATE OUTFILE='C:\temp\kadaster\werkbestanden\eigendom met ongelijke resultaten.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /FIELDNAMES VALUE=NAMES
  /CELLS=VALUES
/REPLACE.

dataset activate eigadres.
dataset close testbewoondeig.

DATASET ACTIVATE eigadres.

* verwijder beperkt aantal cases met een mismatch.
FILTER OFF.
USE ALL.
SELECT IF (NATIONAAL_NUMMER>0).
EXECUTE.

* gecontroleerd: gezinshoofden worden steeds maar aan ��n enkel eigendom toegekend.

match files
/file=*
/keep=eigendom_id adrescode huidig_bewoond nationaal_nummer.


SAVE OUTFILE='C:\temp\kadaster\werkbestanden\koppeltabel_rrgezinshoofd_eigendom.sav'
  /COMPRESSED.


SAVE TRANSLATE OUTFILE='C:\temp\kadaster\werkbestanden\koppeltabel_rrgezinshoofd_eigendom.sav'
  /TYPE=CSV
  /ENCODING='Locale'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.
