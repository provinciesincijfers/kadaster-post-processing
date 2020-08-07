* Encoding: windows-1252.
CTABLES 
  /VLABELS VARIABLES=bouwjaar_cat woongelegenheden bewoonbaar DISPLAY=LABEL 
  /TABLE bouwjaar_cat > woongelegenheden [SUM] BY bewoonbaar 
  /CATEGORIES VARIABLES=bouwjaar_cat ORDER=A KEY=VALUE EMPTY=INCLUDE 
  /CATEGORIES VARIABLES=bewoonbaar ORDER=A KEY=VALUE EMPTY=EXCLUDE 
  /CRITERIA CILEVEL=95.



DATASET ACTIVATE eigendommen. 
DATASET COPY  j2018bjmiss. 
DATASET ACTIVATE  j2018bjmiss. 
FILTER OFF. 
USE ALL. 
SELECT IF (missing(bouwjaar)). 
EXECUTE. 
DATASET ACTIVATE  eigendommen.

DATASET ACTIVATE j2019bjmiss.
* Custom Tables.
CTABLES
  /VLABELS VARIABLES=aard bewoonbaar wooneenheden woongelegenheden huidig_bewoond DISPLAY=LABEL
  /TABLE aard BY bewoonbaar > (wooneenheden [SUM] + woongelegenheden [SUM] + huidig_bewoond 
    [SUM])
  /CATEGORIES VARIABLES=aard bewoonbaar ORDER=A KEY=VALUE EMPTY=EXCLUDE
  /CRITERIA CILEVEL=95.


DATASET ACTIVATE eigendommen. 
DATASET COPY  j2019bjmiss. 
DATASET ACTIVATE  j2019bjmiss. 
FILTER OFF. 
USE ALL. 
SELECT IF (aard = "APPARTEMENT #"). 
EXECUTE. 
DATASET ACTIVATE  eigendommen.
DATASET ACTIVATE eigendommen2018. 
DATASET COPY  j2018bjmiss. 
DATASET ACTIVATE  j2018bjmiss. 
FILTER OFF. 
USE ALL. 
SELECT IF (aard = "APPARTEMENT #"). 
EXECUTE.

recode bouwjaar_cat (13=0) (else=1) into bouwjaar_dummy.



* Custom Tables.
CTABLES
  /VLABELS VARIABLES=subtype_woning bouwjaar_dummy wooneenheden huidig_bewoond woongelegenheden 
    DISPLAY=LABEL
  /TABLE subtype_woning BY bouwjaar_dummy > (wooneenheden [SUM, COUNT F40.0] + huidig_bewoond [SUM] 
    + woongelegenheden [SUM])
  /CATEGORIES VARIABLES=subtype_woning bouwjaar_dummy ORDER=A KEY=VALUE EMPTY=EXCLUDE
  /CRITERIA CILEVEL=95.
