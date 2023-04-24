* Encoding: windows-1252.
* deze staat opeens in ANSI, dus:.
SET OLang=English Unicode=No Locale=nl_BE Small=0.0001 THREADS=AUTO Printback=On BASETEXTDIRECTION=AUTOMATIC DIGITGROUPING=No TLook=None SUMMARY=None MIOUTPUT=[observed imputed] TFit=Both LEADZERO=No TABLERENDER=light.



* locatie hoofdmap.
DEFINE datamap () 'h:\data\kadaster\' !ENDDEFINE.
* gaat ervan uit dat je deze mappen hebt:
2018: met de bestanden 2018
2019: met de bestanden 2019
enzovoorts.
* werkbestanden: voor alle sav files.
* als bestanden voor een nieuw jaar toekomen:
- maak een mapje met het nieuwe jaartal met die bestanden
- zorg dat KAD_XXXX_koppeling.txt verwijst naar meest recente jaar.

PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + "2018\KAD_2018_eigendom.txt"
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  capakey A17
  eigendom_id F9.0
  straatnaam A100
  KI F5.0
  inkomen A10
  oppervlakte F5.0
  bewoonbaar A1
  aard A100
  afdelingsnummer A5
  bewoner_code A1
  eigenaarstype A8
  medeeigenaars A1
  bouwjaar F4.0
  laatste_wijziging F4.0
  soort_bebouwing A25
  subtype_woning A150
  verdieping F2.0
  bovengrondse_verdiepingen F1.0
  wooneenheden F1.0
  huidig_bewoond F1.0
  max_bewoond F1.0
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME eigendom WINDOW=FRONT.

freq jaartal.

FILTER OFF.
USE ALL.
SELECT IF (jaartal>0).
EXECUTE.


SAVE OUTFILE=datamap + 'werkbestanden\eigendom_2018.sav'
  /COMPRESSED.



PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2018\KAD_2018_parcel.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  propertySituationIdf f9.0
  divCad f5.0
  section a1
  primaryNumber f4.0
  bisNumber f2.0
  exponentLetter a1
  exponentNumber f3.0
  partNumber a5
  capakey A17
  order a2
  nature a3
  descriptPrivate a35
  block f1.0
  floor f4.0
  floorSituation a10
  crossDetail a10
  matUtil a10
  notTaxedMatUtil a10
  nisCom f5.0
  street_situation a50
  street_translation a50
  street_code a5
  number a50
  polWa a7
  surfaceNotTaxable f7.0
  surfaceTaxable f7.0
  surfaceVerif a1
  constructionYear f4.0
  soilIndex f1.0
  soilRent f1.0
  cadastralIncomePerSurface f5.0
  cadastralIncomePerSurfaceOtherDi f3.0
  numberCadastralIncome f1.0
  charCadastralIncome a1
  cadastralIncome f10.0
  dateEndExoneration a15
  decrete f3.0
  constructionIndication f3.0
  constructionType a1
  floorNumberAboveground f3.0
  garret f1.0
  physModYear a4.0
  constructionQuality a1
  garageNumber f4.0
  centralHeating f1.0
  bathroomNumber f4.0
  housingUnitNumber f4.0
  placeNumber f4.0
  builtSurface f8.0
  usedSurface f6.0
  dateSituation edate10
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME parcel WINDOW=FRONT.

rename variables propertySituationIdf=eigendom_id.

SAVE OUTFILE=datamap + 'werkbestanden\parcel_2018.sav'
  /COMPRESSED.



PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2019\KAD_2019_eigendom.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  capakey A17
  eigendom_id F9.0
  straatnaam A100
  KI F5.0
  inkomen A10
  oppervlakte F5.0
  bewoonbaar A1
  aard A100
  afdelingsnummer A5
  bewoner_code A1
  eigenaarstype A8
  medeeigenaars A1
  bouwjaar F4.0
  laatste_wijziging F4.0
  soort_bebouwing A25
  subtype_woning A150
  verdieping F2.0
  bovengrondse_verdiepingen F1.0
  wooneenheden F1.0
  huidig_bewoond F1.0
  max_bewoond F1.0
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME eigendom WINDOW=FRONT.

freq jaartal.



SAVE OUTFILE=datamap + 'werkbestanden\eigendom_2019.sav'
  /COMPRESSED.



PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2019\KAD_2019_parcel.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  propertySituationIdf f9.0
  divCad f5.0
  section a1
  primaryNumber f4.0
  bisNumber f2.0
  exponentLetter a1
  exponentNumber f3.0
  partNumber a5
  capakey A17
  order a2
  nature a3
  descriptPrivate a35
  block f1.0
  floor f4.0
  floorSituation a10
  crossDetail a10
  matUtil a10
  notTaxedMatUtil a10
  nisCom f5.0
  street_situation a50
  street_translation a50
  street_code a5
  number a50
  polWa a7
  surfaceNotTaxable f7.0
  surfaceTaxable f7.0
  surfaceVerif a1
  constructionYear f4.0
  soilIndex f1.0
  soilRent f1.0
  cadastralIncomePerSurface f5.0
  cadastralIncomePerSurfaceOtherDi f3.0
  numberCadastralIncome f1.0
  charCadastralIncome a1
  cadastralIncome f10.0
  dateEndExoneration a15
  decrete f3.0
  constructionIndication f3.0
  constructionType a1
  floorNumberAboveground f3.0
  garret f1.0
  physModYear a4.0
  constructionQuality a1
  garageNumber f4.0
  centralHeating f1.0
  bathroomNumber f4.0
  housingUnitNumber f4.0
  placeNumber f4.0
  builtSurface f8.0
  usedSurface f6.0
  dateSituation edate10
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME parcel WINDOW=FRONT.

rename variables propertySituationIdf=eigendom_id.

SAVE OUTFILE=datamap + 'werkbestanden\parcel_2019.sav'
  /COMPRESSED.


PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2020\KAD_2020_eigendom.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  capakey A17
  eigendom_id F9.0
  straatnaam A100
  KI F5.0
  inkomen A10
  oppervlakte F5.0
  bewoonbaar A1
  aard A100
  afdelingsnummer A5
  bewoner_code A1
  eigenaarstype A8
  medeeigenaars A1
  bouwjaar F4.0
  laatste_wijziging F4.0
  soort_bebouwing A25
  subtype_woning A150
  verdieping F2.0
  bovengrondse_verdiepingen F1.0
  wooneenheden F1.0
  huidig_bewoond F1.0
  max_bewoond F1.0
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME eigendom WINDOW=FRONT.

freq jaartal.



SAVE OUTFILE=datamap + 'werkbestanden\eigendom_2020.sav'
  /COMPRESSED.



PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2020\KAD_2020_parcel.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  propertySituationIdf f9.0
  divCad f5.0
  section a1
  primaryNumber f4.0
  bisNumber f2.0
  exponentLetter a1
  exponentNumber f3.0
  partNumber a5
  capakey A17
  order a2
  nature a3
  descriptPrivate a35
  block f1.0
  floor f4.0
  floorSituation a10
  crossDetail a10
  matUtil a10
  notTaxedMatUtil a10
  nisCom f5.0
  street_situation a50
  street_translation a50
  street_code a5
  number a50
  polWa a7
  surfaceNotTaxable f7.0
  surfaceTaxable f7.0
  surfaceVerif a1
  constructionYear f4.0
  soilIndex f1.0
  soilRent f1.0
  cadastralIncomePerSurface f5.0
  cadastralIncomePerSurfaceOtherDi f3.0
  numberCadastralIncome f1.0
  charCadastralIncome a1
  cadastralIncome f10.0
  dateEndExoneration a15
  decrete f3.0
  constructionIndication f3.0
  constructionType a1
  floorNumberAboveground f3.0
  garret f1.0
  physModYear a4.0
  constructionQuality a1
  garageNumber f4.0
  centralHeating f1.0
  bathroomNumber f4.0
  housingUnitNumber f4.0
  placeNumber f4.0
  builtSurface f8.0
  usedSurface f6.0
  dateSituation edate10
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME parcel WINDOW=FRONT.

rename variables propertySituationIdf=eigendom_id.

SAVE OUTFILE=datamap + 'werkbestanden\parcel_2020.sav'
  /COMPRESSED.


PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2021\KAD_2021_eigendom.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  capakey A17
  eigendom_id F9.0
  straatnaam A100
  KI F5.0
  inkomen A10
  oppervlakte F5.0
  bewoonbaar A1
  aard A100
  afdelingsnummer A5
  bewoner_code A1
  eigenaarstype A8
  medeeigenaars A1
  bouwjaar F4.0
  laatste_wijziging F4.0
  soort_bebouwing A25
  subtype_woning A150
  verdieping F2.0
  bovengrondse_verdiepingen F1.0
  wooneenheden F1.0
  huidig_bewoond F1.0
  max_bewoond F1.0
  woongelegenheden F8.0
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME eigendom WINDOW=FRONT.

freq jaartal.



SAVE OUTFILE=datamap + 'werkbestanden\eigendom_2021.sav'
  /COMPRESSED.



PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2021\KAD_2021_parcel.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  propertySituationIdf f9.0
  divCad f5.0
  section a1
  primaryNumber f4.0
  bisNumber f2.0
  exponentLetter a1
  exponentNumber f3.0
  partNumber a5
  capakey A17
  order a2
  nature a3
  descriptPrivate a35
  block f1.0
  floor f4.0
  floorSituation a10
  crossDetail a10
  matUtil a10
  notTaxedMatUtil a10
  nisCom f5.0
  street_situation a50
  street_translation a50
  street_code a5
  number a50
  polWa a7
  surfaceNotTaxable f7.0
  surfaceTaxable f7.0
  surfaceVerif a1
  constructionYear f4.0
  soilIndex f1.0
  soilRent f1.0
  cadastralIncomePerSurface f5.0
  cadastralIncomePerSurfaceOtherDi f3.0
  numberCadastralIncome f1.0
  charCadastralIncome a1
  cadastralIncome f10.0
  dateEndExoneration a15
  decrete f3.0
  constructionIndication f3.0
  constructionType a1
  floorNumberAboveground f3.0
  garret f1.0
  physModYear a4.0
  constructionQuality a1
  garageNumber f4.0
  centralHeating f1.0
  bathroomNumber f4.0
  housingUnitNumber f4.0
  placeNumber f4.0
  builtSurface f8.0
  usedSurface f6.0
  dateSituation edate10
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME parcel WINDOW=FRONT.

rename variables propertySituationIdf=eigendom_id.

SAVE OUTFILE=datamap + 'werkbestanden\parcel_2021.sav'
  /COMPRESSED.


PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2022\KAD_2022_eigendom.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  capakey A17
  eigendom_id F9.0
  straatnaam A100
  KI F5.0
  inkomen A10
  oppervlakte F5.0
  bewoonbaar A1
  aard A100
  afdelingsnummer A5
  bewoner_code A1
  eigenaarstype A8
  medeeigenaars A1
  bouwjaar F4.0
  laatste_wijziging F4.0
  soort_bebouwing A25
  subtype_woning A150
  verdieping F2.0
  bovengrondse_verdiepingen F1.0
  wooneenheden F1.0
  huidig_bewoond F1.0
  max_bewoond F1.0
  woongelegenheden F8.0
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME eigendom WINDOW=FRONT.

freq jaartal.



SAVE OUTFILE=datamap + 'werkbestanden\eigendom_2022.sav'
  /COMPRESSED.



PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2022\KAD_2022_parcel.txt'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  propertySituationIdf f9.0
  divCad f5.0
  section a1
  primaryNumber f4.0
  bisNumber f2.0
  exponentLetter a1
  exponentNumber f3.0
  partNumber a5
  capakey A17
  order a2
  nature a3
  descriptPrivate a35
  block f1.0
  floor f4.0
  floorSituation a10
  crossDetail a10
  matUtil a10
  notTaxedMatUtil a10
  nisCom f5.0
  street_situation a50
  street_translation a50
  street_code a5
  number a50
  polWa a7
  surfaceNotTaxable f7.0
  surfaceTaxable f7.0
  surfaceVerif a1
  constructionYear f4.0
  soilIndex f1.0
  soilRent f1.0
  cadastralIncomePerSurface f5.0
  cadastralIncomePerSurfaceOtherDi f3.0
  numberCadastralIncome f1.0
  charCadastralIncome a1
  cadastralIncome f10.0
  dateEndExoneration a15
  decrete f3.0
  constructionIndication f3.0
  constructionType a1
  floorNumberAboveground f3.0
  garret f1.0
  physModYear a4.0
  constructionQuality a1
  garageNumber f4.0
  centralHeating f1.0
  bathroomNumber f4.0
  housingUnitNumber f4.0
  placeNumber f4.0
  builtSurface f8.0
  usedSurface f6.0
  dateSituation edate10
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME parcel WINDOW=FRONT.

rename variables propertySituationIdf=eigendom_id.

SAVE OUTFILE=datamap + 'werkbestanden\parcel_2022.sav'
  /COMPRESSED.



* deze steeds enkel voor het meest recente jaar.
PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE=datamap + '2022\KAD_2022_koppeling.txt'
  /ENCODING='UTF8'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  capakey A17
  niscode F5.0
  stat_sector A9
  bouwblok_code A50
  kern A50
  deelgemeente A50
  laatste_jaar F4.0
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME koppeling WINDOW=FRONT.


DATASET ACTIVATE koppeling.

*FILTER OFF.
*USE ALL.
*SELECT IF (jaartal>0).
*EXECUTE.

SAVE OUTFILE=datamap + 'werkbestanden\koppeling_meest_recent.sav'
  /COMPRESSED.


* de eerste vijf tekens van de capakey bevatten een code die lijken op een niscode en die steeds volledig binnen één gemeente liggen.
* we maken een tabel die het mogelijk maakt om op basis van die 5 tekens de niscode op te zoeken.
* die tabel gebruiken we later om percelen (met unieke sleutel capakey) die niet aan een statsec gekoppeld kunnen worden toch nog aan een gemeente te koppelen.
STRING  capa5 (A5).
COMPUTE capa5=capakey.
EXECUTE.

DATASET ACTIVATE koppeling.
DATASET DECLARE tussentabel.
AGGREGATE
  /OUTFILE='tussentabel'
  /BREAK=capa5 niscode
  /N_BREAK=N.
dataset activate tussentabel.
alter type capa5 (f5.0).

DATASET ACTIVATE tussentabel.
* we verwijderden enkel ongeldige percelen.
FILTER OFF.
USE ALL.
SELECT IF (capa5 > 0).
EXECUTE.
* Identify Duplicate Cases.
SORT CASES BY capa5(A) N_BREAK(A).
MATCH FILES
  /FILE=*
  /BY capa5
  /LAST=PrimaryLast.
VARIABLE LABELS  PrimaryLast 'Indicator of each last matching case as Primary'.
VALUE LABELS  PrimaryLast 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryLast (ORDINAL).
EXECUTE.
FILTER OFF.
USE ALL.
SELECT IF (PrimaryLast=1).
EXECUTE.
match files
/file=*
/keep=capa5
niscode.
alter type capa5 (a5).
sort cases capa5 (a).



SAVE OUTFILE=datamap + 'werkbestanden\x_capa5_niscode.sav'
  /COMPRESSED.



SAVE TRANSLATE OUTFILE=datamap + 'werkbestanden\capa5_niscode.csv'
  /TYPE=CSV
  /ENCODING='UTF8'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.

dataset close koppeling.
dataset close eigendom.
