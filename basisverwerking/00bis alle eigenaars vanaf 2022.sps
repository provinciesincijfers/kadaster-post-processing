* Encoding: windows-1252.
* deze staat opeens in ANSI, dus:.
SET OLang=English Unicode=No Locale=nl_BE Small=0.0001 THREADS=AUTO Printback=On BASETEXTDIRECTION=AUTOMATIC DIGITGROUPING=No TLook=None SUMMARY=None MIOUTPUT=[observed imputed] TFit=Both LEADZERO=No TABLERENDER=light.



* locatie hoofdmap.
DEFINE datamap () 'H:\data\kadaster\' !ENDDEFINE.
* gaat ervan uit dat je deze mappen hebt:
2021: met de bestanden 2021
2022: met de bestanden 2022
enzovoorts.
* werkbestanden: voor alle sav files.
* als bestanden voor een nieuw jaar toekomen:
- maak een mapje met het nieuwe jaartal met die bestanden
- zorg dat KAD_XXXX_koppeling.txt verwijst naar meest recente jaar.


PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE= datamap + "2022\KAD_2022_alle_eigenaars.txt"
  /DELCASE=LINE
  /DELIMITERS="\t"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  provincie A4
  jaartal F4.0
  eigendom_id F15.0
  naam A255
  identificatie A10
  landcode A2
  postcode A25
  gemeente A100
  straatnaam A150
  huisbis A25
  subadres A25
  volgorde F8.0
  recht A127
  type_persoon A1
  /MAP.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME alleeigenaars WINDOW=FRONT.

SAVE OUTFILE=datamap + 'werkbestanden\alle_eigenaars_2022.sav'
  /COMPRESSED.


* BASISAFSPRAKEN:

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=eigendom_id
  /aantal_eigenaars=N.
* OPGELET: er zijn gevallen waar het maximum van "volgorde" kleiner is dan het "aantal eigenaars".

* DIT IS NIET MEER NODIG, we hebben nu al een betere classificatie.
*- classificeren eigenaars.
*recode naam (""=1) (else=2) into persoon_rechtspersoon.
*if identificatie="" persoon_rechtspersoon = 3.
*value labels persoon_rechtspersoon
1 'persoon'
2 'rechtspersoon'
3 'onbekend'.

* - BE/buitenland. 
recode landcode ("BE"=1) (""=3) (else=2) into belgisch_eigenaar.
value labels belgisch_eigenaar
1 'Belgisch'
2 'buitenlands'
3 'onbekend'.

* recht verwerken.


* stap 1: splits op in een deel verdeelsleutel en een deel over het einde van het recht.
* gebaseerd op https://github.com/StudiedienstAntwerpen/be-cadastre/blob/master/methode_vanaf_2016/n03_basis_eigenaars.sps.

string right_verdeelsleutel (a50).
* isoleer de verdeelsleutel.
compute right_verdeelsleutel=recht.

* verwijder liggende streepjes aan begin en einde van de verdeelsleutel.
compute right_verdeelsleutel=ltrim(rtrim(rtrim(replace(right_verdeelsleutel,"(","")),"-"),"-").

* we werken met een tijdelijke kopie van de verdeelsleutel (eig_deel1) voor de verwerking tot omschrijvingen van de verdeling.
STRING  eig_deel1 (A70).
COMPUTE eig_deel1=right_verdeelsleutel.

* we identificeren de eerste breuk en zijn omschrijving.
* op zoek naar de positie van het eerste nummer.
COMPUTE nummer1=CHAR.INDEX(eig_deel1,"1234567890",1).
* op zoek naar de positie van de eerste / na het eerste nummer (er kunnen immers ook / staan in de tekst).
COMPUTE slash1=char.index(char.substr(eig_deel1,nummer1),"/").
* nul ("niets gevonden") op missing zetten, zodat in verdere stappen er geen false positives ontstaan.
recode slash1 nummer1 (0=sysmis).
* we berekenen de absolute positie van de eerste slash.
COMPUTE slash1=slash1+nummer1-1.
* op zoek naar de eerste spatie na een slash, dus het einde van de eerste breuk. Opgelet, dit is het aantal tekens te rekenen vanaf de slash, niet vanaf het begin.
compute spatie_na_slash1=char.index(char.substr(eig_deel1,slash1+1)," ").
* maak de eerste omschrijving aan en vul op met het eerste niet-numeriek deel.
string omschrijving1 (a50).
compute omschrijving1=char.substr(eig_deel1,1,nummer1-1).
* vul op met het hele basisveld indien er geen breuk in de tekst staat.
if missing(slash1) omschrijving1=eig_deel1.
* vul de eerste teller en eerste noemer in.
compute teller1=number(char.substr(eig_deel1,nummer1,slash1-nummer1),f8.0).
compute noemer1=number(char.substr(eig_deel1,slash1+1,spatie_na_slash1-1),f8.0).

* soms is er nog een tweede tekst en tweede breuk beschikbaar.
* we gaan op zoek naar tekst na de eerste breuk.
compute tekst2=CHAR.INDEX(char.substr(eig_deel1,spatie_na_slash1+slash1),"ABCDEFGHIJKLMNOZPQRSTUVWXYZ",1).
* we gaan op zoek naar een cijfer na de eerste breuk.
compute nummer2=CHAR.INDEX(char.substr(eig_deel1,spatie_na_slash1+slash1),"1234567890",1).
* als we tekst gevonden zouden hebben, dan geven we de absolute positie van die tekst aan.
if tekst2>0 positietekst2=tekst2+spatie_na_slash1+slash1-1.
* als we een cijfer gevonden zouden hebben, dan geven we de absolute positie van dat nummer aan.
if nummer2>0 positienummer2=nummer2+spatie_na_slash1+slash1-1.
string omschrijving2 (a50).
* als er geen tweede cijfer is, dan nemen we gewoon de rest mee als tekst.
if missing(positienummer2) omschrijving2=char.substr(eig_deel1,positietekst2).
* is er wel nog een cijfer, dan nemen we enkel het deel voor dat cijfer mee.
if positienummer2>0 omschrijving2=char.substr(eig_deel1,positietekst2,nummer2-tekst2).
* als er nog een slash is na de eerste slash in een breuk, dan berekenen we er de absolute positie van.
if CHAR.INDEX(char.substr(eig_deel1,slash1+1),"/")>0 slash2=CHAR.INDEX(char.substr(eig_deel1,slash1+1),"/")+slash1.
* daarmeer kunen we de tweede teller en niemer opsporen.
compute teller2=number(char.substr(eig_deel1,positienummer2,char.index(char.substr(eig_deel1,positienummer2),"/")-1),f8.0).
compute noemer2=number(char.substr(eig_deel1,slash2+1,char.index(char.substr(eig_deel1,slash2)," ")-1),f8.0).

* spaties wissen.
compute omschrijving1=ltrim(rtrim(omschrijving1)).
compute omschrijving2=ltrim(rtrim(omschrijving2)).


* geen zorgen dat hier een hoop errors zijn van invalid substrings.
EXECUTE.
delete variables eig_deel1
nummer1
slash1
spatie_na_slash1
tekst2
nummer2
positietekst2
positienummer2
slash2.

alter type teller1
noemer1
teller2
noemer2 (f8.0).

* beslis welke breuken we meenemen uit deel1.
* bereken de waarde.
* doe hetzelfde met deel2 en tel op.

*if any(ltrim(rtrim(omschrijving1)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 meetellen=1.
*if any(ltrim(rtrim(omschrijving1)),"VG","ERFP","OPSTAL")=1 meetellen=0.

string omschrijving1_clean (a50).
string omschrijving2_clean (a50).
recode omschrijving1 omschrijving2
('GEBOUW VE'='GEBOUW VE')
('ONB'='ONB')
('VERP GROND'='VERP GROND')
('VERP'='VERP')
('BE'='BE')
('VE'='VE')
('NP'='NP')
('PP'='PP')
('VE-BEZ-OPSTAL'='VE-BEZ-OPSTAL')
('EIG.GROND'='EIG.GROND')
('EIG.GROND DEEL'='EIG.GROND DEEL')
('VG BE'='VG BE')
('GEBOUW'='GEBOUW')
('VE-BEZ-ERFP'='VE-BEZ-ERFP')
('VG'='VG')
('ERFP'='ERFP')
('OPSTAL'='OPSTAL')
('GROND'='GROND')
('BE-BEZ-OPSTAL'='BE-BEZ-OPSTAL')
('EVG'='EVG')
('BEWONING'='BEWONING')
('CR'='CR')
('DEEL'='DEEL')
('GEBR/BEWON'='GEBR/BEWON')
('GEBRUIK'='GEBRUIK')
into omschrijving1_clean omschrijving2_clean.

string omschrijving1_temp (a50).
if omschrijving1_clean="" & char.index(omschrijving1," ")>0 omschrijving1_temp=char.substr(omschrijving1,1,char.index(omschrijving1," ")-1).
if omschrijving1_clean="" & char.index(omschrijving1,"-")>0 omschrijving1_temp=char.substr(omschrijving1,1,char.index(omschrijving1,"-")-1).
recode omschrijving1_temp ("VR"="VERP").

string omschrijving2_temp (a50).
if omschrijving2_clean="" & char.index(omschrijving2," ")>0 omschrijving2_temp=char.substr(omschrijving2,1,char.index(omschrijving2," ")-1).
if omschrijving2_clean="" & char.index(omschrijving2,"-")>0 omschrijving2_temp=char.substr(omschrijving2,1,char.index(omschrijving2,"-")-1).
recode omschrijving2_temp ("VR"="VERP").


do if omschrijving1_clean="" .
recode omschrijving1_temp
('GEBOUW VE'='GEBOUW VE')
('ONB'='ONB')
('VERP GROND'='VERP GROND')
('VERP'='VERP')
('BE'='BE')
('VE'='VE')
('NP'='NP')
('PP'='PP')
('VE-BEZ-OPSTAL'='VE-BEZ-OPSTAL')
('EIG.GROND'='EIG.GROND')
('EIG.GROND DEEL'='EIG.GROND DEEL')
('VG BE'='VG BE')
('GEBOUW'='GEBOUW')
('VE-BEZ-ERFP'='VE-BEZ-ERFP')
('VG'='VG')
('ERFP'='ERFP')
('OPSTAL'='OPSTAL')
('GROND'='GROND')
('BE-BEZ-OPSTAL'='BE-BEZ-OPSTAL')
('EVG'='EVG')
('BEWONING'='BEWONING')
('CR'='CR')
('DEEL'='DEEL')
('GEBR/BEWON'='GEBR/BEWON')
('GEBRUIK'='GEBRUIK')
into omschrijving1_clean.
end if.

do if omschrijving2_clean="" .
recode omschrijving2_temp
('GEBOUW VE'='GEBOUW VE')
('ONB'='ONB')
('VERP GROND'='VERP GROND')
('VERP'='VERP')
('BE'='BE')
('VE'='VE')
('NP'='NP')
('PP'='PP')
('VE-BEZ-OPSTAL'='VE-BEZ-OPSTAL')
('EIG.GROND'='EIG.GROND')
('EIG.GROND DEEL'='EIG.GROND DEEL')
('VG BE'='VG BE')
('GEBOUW'='GEBOUW')
('VE-BEZ-ERFP'='VE-BEZ-ERFP')
('VG'='VG')
('ERFP'='ERFP')
('OPSTAL'='OPSTAL')
('GROND'='GROND')
('BE-BEZ-OPSTAL'='BE-BEZ-OPSTAL')
('EVG'='EVG')
('BEWONING'='BEWONING')
('CR'='CR')
('DEEL'='DEEL')
('GEBR/BEWON'='GEBR/BEWON')
('GEBRUIK'='GEBRUIK')
into omschrijving2_clean.
end if.



recode omschrijving1_clean omschrijving2_clean
('GEBOUW VE'=1)
('ONB'=1)
('VERP GROND'=1)
('VERP'=1)
('BE'=1)
('VE'=1)
('NP'=1)
('PP'=1)
('VE-BEZ-OPSTAL'=1)
('EIG.GROND'=1)
('EIG.GROND DEEL'=1)
('VG BE'=1)
('GEBOUW'=1)
('VE-BEZ-ERFP'=1)
('VG'=0)
('ERFP'=0)
('OPSTAL'=0)
('GROND'=1)
('BE-BEZ-OPSTAL'=1)
('EVG'=0)
('BEWONING'=0)
('CR'=0)
('DEEL'=1)
('GEBR/BEWON'=0)
('GEBRUIK'=0)
into meenemen_teller1 meenemen_teller2.


* wat nemen we expliciet mee.
if meenemen_teller1=1 eigendom_teller=teller1.
if meenemen_teller1=1 eigendom_noemer=noemer1.
if meenemen_teller2=1 eigendom_teller2=teller2.
if meenemen_teller2=1 eigendom_noemer2=noemer2.


*wat nemen we expliciet niet mee.
if meenemen_teller1=0 eigendom_teller=0.
if meenemen_teller1=0 eigendom_noemer=1.
if meenemen_teller2=0 eigendom_teller2=0.
if meenemen_teller2=0 eigendom_noemer2=1.


* indien er geen breuk kon gevormd worden, dan gaan we ervan uit dat de omschrijving op de hele eigendom slaat.

if meenemen_teller1=1 & missing(teller1) eigendom_teller=1.
if meenemen_teller1=1 & missing(noemer1) eigendom_noemer=1.
if meenemen_teller2=1 & missing(teller2) eigendom_teller2=1.
if meenemen_teller2=1 & missing(noemer2) eigendom_noemer2=1.


* bereken de breuk.
compute aandeel_eigendom=eigendom_teller/eigendom_noemer.
if eigendom_teller2/eigendom_noemer2>0 aandeel_eigendom=aandeel_eigendom+eigendom_teller2/eigendom_noemer2.
if missing(aandeel_eigendom) aandeel_eigendom=eigendom_teller2/eigendom_noemer2.
* als mensen meer dan 100% eigenaar zijn, ronden we af naar 100%.
if aandeel_eigendom>1 aandeel_eigendom=1.


* we testen het resultaat.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=eigendom_id
  /som_aandelen=SUM(aandeel_eigendom)
  /aantal_eigenaars=N.

* indien het resultaat niet ok is, maar is maar één eigenaar gekend, dan geven we die eigenaar de volledige eigendom.
if aantal_eigenaars=1 & (som_aandelen=0 | missing(som_aandelen)) aandeel_eigendom=1.
* wanneer er geen breuken beschikbaar zijn, maar er is wel info dat iemand verpacht, dan geven we die volledige eigendom.
if som_aandelen=0 & (omschrijving1="VERP" | omschrijving1="VERP DEEL") aandeel_eigendom=1.

* we controleren opnieuw.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=eigendom_id
  /som_aandelen=SUM(aandeel_eigendom).


* potentiele eigenaars meenemen.
if missing(aandeel_eigendom) potentiele_eigenaar=1.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=eigendom_id
  /som_aandelen=SUM(aandeel_eigendom)
  /som_potentiele_eigenaar=sum(potentiele_eigenaar).

*if som_aandelen=0 & missing(aandeel_eigendom) aandeel_eigendom=1.
compute aandeel_eigendom=aandeel_eigendom/som_aandelen.
if (missing(som_aandelen) | som_aandelen=0) & missing(aandeel_eigendom) & potentiele_eigenaar=1 aandeel_eigendom=1/som_potentiele_eigenaar.
EXECUTE.

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=eigendom_id
  /som_aandelen=SUM(aandeel_eigendom).
freq som_aandelen.




match files
/file=*
/keep=provincie
jaartal
eigendom_id
naam
identificatie
landcode
postcode
gemeente
straatnaam
huisbis
subadres
volgorde
recht
aandeel_eigendom
type_persoon
belgisch_eigenaar
omschrijving1_clean
teller1
noemer1
omschrijving2_clean
teller2
noemer2.
sort cases eigendom_id (a).
rename variables (
omschrijving1_clean
omschrijving2_clean=
omschrijving1
omschrijving2).



SAVE OUTFILE=datamap + 'werkbestanden\basisafspraken_alle_eigenaars_2022.sav'
  /COMPRESSED.


SAVE TRANSLATE OUTFILE=datamap + 'werkbestanden\basisafspraken_alle_eigenaars_2022.csv'
  /TYPE=CSV
  /ENCODING='Locale'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES
/replace.

SAVE TRANSLATE OUTFILE=datamap + 'werkbestanden\basisafspraken_alle_eigenaars_2022.sas7bdat'
  /TYPE=SAS
  /VERSION=7
  /PLATFORM=WINDOWS
  /ENCODING='Locale'
  /MAP
  /REPLACE.




