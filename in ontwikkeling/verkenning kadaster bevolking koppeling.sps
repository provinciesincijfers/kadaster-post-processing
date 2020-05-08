* Encoding: windows-1252.
1) inwoners naar tabel rrcrab koppelen
MAAR sommige zijn dubbel
deels kunnen opkuisen door index te gebruiken
en anders kiezen? at random?
zitten daar nog dubbels in op crabadres???


2) van rrcrab naar eigendomadres
in tabel eigendomadres komt zelfde crabadres mogelijk vele keren voor



dataset name eigendomadres.


koppelen beginnen vanaf eigendommen

huidig bewoond  naar eigendomadres
> moeten dan nog verdeeld over de verschillende opties

sort cases eigendom_id (a).
if $casenum=1 internvolgnummer=1.
if lag(eigendom_id)~=(eigendom_id) internvolgnummer=1.
if lag(eigendom_id)=(eigendom_id) internvolgnummer=lag(internvolgnummer)+1.
EXECUTE.






* vereenvoudig bevolking.
GET 
  SAS DATA='C:\temp\overstroming\i_lhc2_2019.sas7bdat'.
DATASET NAME bevolking WINDOW=FRONT. 

if NATIONAAL_NUMMER = RRNR_HOOFDPERSOON & refpers = "N" collectief=1.
if  NATIONAAL_NUMMER = RRNR_HOOFDPERSOON & refpers = "J" privaat=1.
if  NATIONAAL_NUMMER ~= RRNR_HOOFDPERSOON gezinslid=1.
compute inwoner=1.
EXECUTE.

DATASET ACTIVATE bevolking.
DATASET DECLARE huishoudens.
AGGREGATE
  /OUTFILE='huishoudens'
  /BREAK=ADRESCODE RRNR_HOOFDPERSOON
  /privaat_hh=sum(privaat)
  /gezinsleden=N.
dataset activate huishoudens.
dataset close bevolking.

