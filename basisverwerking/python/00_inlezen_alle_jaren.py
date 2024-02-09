# -*- coding: utf-8 -*-
"""
Created on Thu Oct  5 12:13:10 2023

"""

# =============================================================================
#                                   CONFIGURATIE
# =============================================================================

# Encoding = windows-1252, in ANSI Latin 1
# Importeer de nodige modules en declareer de main directory
import pandas as pd
pd.set_option('display.max.columns', None)
import os
os.chdir('D:\data\kadaster')

# =============================================================================
#       DEEL 1: KOPPELING (ENKEL DRAAIEN VOOR HET MEEST RECENTE JAAR)
# =============================================================================

# Lees de koppeling in 
jaartal = '2023' # Vul hier het meest recente jaartal in
col_names = ['provincie', 'jaartal', 'capakey', 'niscode', 'stat_sector', 'bouwblok_code', 'kern', 'deelgemeente', 'wijkcode', 'laatste_jaar']
koppeling = pd.read_csv(jaartal + '\KAD_' + jaartal + '_koppeling.txt', delimiter='\t', encoding='latin-1', names=col_names, header=0,
                        dtype={'provincie':'string', 'jaartal':'int', 'capakey':'string', 'niscode':'string', 'stat_sector':'string',
                               'bouwblok_code':'string', 'kern': 'string', 'deelgemeente':'string', 'wijkcode': 'string', 'laatste_jaar':'int'})
koppeling.to_feather('werkbestanden_python\koppeling_meest_recent.feather')

# De eerste vijf tekens van de capakey bevatten een code die lijkt op een niscode en die steeds volledig binnen een gemeente liggen
# We maken een tabel die het mogelijk maakt om op basis van die vijf tekens de niscode op te zoeken
# Die tabel gebruken we later om percelen (met unieke sleutel capakey) die niet aan een statsec gekoppeld kunnen worden, toch nog aan een gemeente te koppelen
# Voer uit en kuis verder op

koppeling['capa5'] = koppeling['capakey'].str[:5] # Voeg een kolom toe met de eerste 5 karakters van de capakey
tussentabel = koppeling[['capa5', 'niscode']].groupby(['capa5', 'niscode']).size().reset_index().rename(columns={0:'N_BREAK'}) # Groepeer met capa5 en niscode, en tel het aantal cases per groep
tussentabel['capa5'] = pd.to_numeric(tussentabel['capa5'], errors='coerce') # In het geval de conversie naar numerieke waarden onmogelijk is, verander dan naar NaN waarden (in lijn met het SPSS script)
tussentabel = tussentabel.dropna(subset=['capa5']).reset_index(drop=True) # Verwijder missing (niet-numerieke) percelen
tussentabel = tussentabel.sort_values(['capa5', 'N_BREAK'], ascending = True)
tussentabel = tussentabel.drop_duplicates(subset=['capa5'], keep='last').drop(columns=['N_BREAK']).reset_index(drop=True) # Verwijder duplicaten (in lijn met het SPSS script: behoud het laatste voorkomen)
tussentabel['capa5'] = tussentabel['capa5'].astype(int)

# Exporteer naar een .csv, een .feather en een .sav bestand
tussentabel.to_csv('werkbestanden_python\capa5_niscode.csv', sep=';', index = False) # NB. de delimiter kan variëren naargelang jouw computer settings. Check alvorens verder te gaan.
tussentabel.to_feather('werkbestanden_python\capa5_niscode.feather')
del col_names
del koppeling
del tussentabel

# =============================================================================
#                           RECURRENT INLEZEN ALLE JAREN
# =============================================================================

periode = ['2018', '2019', '2020', '2021', '2022', '2023'] # Voeg het meest recente jaartal toe

for jaartal in periode:
    
# =============================================================================
#                               DEEL 2: EIGENDOM
# =============================================================================

    # Het proces is gelijkaardig voor de verschillende datajaren. Uitzonderingen worden aangepakt in de if-statements.
    eigendom = pd.read_csv(jaartal + '\KAD_'+ jaartal + '_eigendom.txt', delimiter = '\t', encoding = 'latin1', dtype = 'string')
    if jaartal == '2020': # Er is een correctie nodig vanwege de incorrecte positie van de header in de input file
        eigendom.columns = eigendom.iloc[5]
        eigendom = eigendom.drop(eigendom.index[5]).reset_index(drop = True) 
    numeric_columns = ['jaartal', 'eigendom_id', 'KI', 'oppervlakte', 'bouwjaar_code', 'laatste_wijziging', 'verdieping',
                       'bovengrondse_verdiepingen', 'wooneenheden', 'huidig_bewoond', 'maximum_bewoond', 'woongelegenheden'] # In lijn met het SPSS script. Verifieer of dit nog steeds nodig is.
    eigendom[numeric_columns] = eigendom[numeric_columns].apply(pd.to_numeric, errors='coerce')
    eigendom = eigendom.rename(columns={'woonfunctie':'bewoonbaar', 'soort_bewoner':'bewoner_code', 'bouwjaar_code':'bouwjaar', 'maximum_bewoond':'max_bewoond'})
    if int(jaartal) < 2021: # Vanaf 2021 wordt de kolom 'woongelegenheden' in acht genomen.
        eigendom = eigendom.drop(columns = 'woongelegenheden')
    if jaartal == '2018':
        eigendom = eigendom[eigendom["jaartal"] > 0] # In lijn met het SPSS script. Verifieer of dit nog steeds nodig is.
    #eigendom.to_csv('werkbestanden_python\eigendom_' + jaartal + '.csv', sep=';', index = False) # Enkel voor langetermijnopslag. Neemt veel geheugen en tijd in.
    eigendom.to_feather('werkbestanden_python\eigendom_' + jaartal + '.feather') # Dit formaat draagt de voorkeur (optimale I/O speed, consumed memory and disk space)
     
    
# =============================================================================
#                               DEEL 3: PARCEL
# =============================================================================

    parcel = pd.read_csv(jaartal + '\KAD_' + jaartal + '_parcel.txt', delimiter = '\t', encoding = 'latin1', dtype = 'string')
    # We declareren de datatypes in lijn met het SPSS script. Tijdens het transformeren naar integers, krijgen we errors vanwege niet-numerieke waarden. Declareer in deze gevallen NaN waarden.
    numeric_columns = ['propertySituationIdf', 'divCad', 'primaryNumber', 'bisNumber', 'exponentNumber', 'block', 'floor', 'nisCom',
           'surfaceNotTaxable', 'surfaceTaxable', 'constructionYear', 'soilIndex', 'soilRent', 'cadastralIncomePerSurface',
           'cadastralIncomePerSurfaceOtherDi', 'numberCadastralIncome', 'cadastralIncome', 'decrete', 'constructionIndication',
           'floorNumberAboveground', 'garret', 'garageNumber', 'centralHeating', 'bathroomNumber', 'housingUnitNumber', 'placeNumber',
           'builtSurface', 'usedSurface'] # De kolommen zijn identiek in elke jaargang. 
    parcel[numeric_columns] = parcel[numeric_columns].apply(pd.to_numeric, errors='coerce')
    parcel = parcel.rename(columns={'propertySituationIdf':'eigendom_id'})
    #parcel.to_csv('werkbestanden_python\parcel_2018.csv', sep=';', index = False) # Enkel voor langetermijnopslag. Neemt veel geheugen en tijd in beslag.
    parcel.to_feather('werkbestanden_python\parcel_' + jaartal + '.feather') 

