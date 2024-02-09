# -*- coding: utf-8 -*-
"""
Created on Mon Oct  9 09:59:13 2023

"""

# =============================================================================
#                               CONFIGURATIE
# =============================================================================

# Encoding = windows-1252, in ANSI Latin 1
# Importeer de nodige modules en declareer de main directory
import pandas as pd
pd.set_option('display.max.columns', None)
import sys
import numpy as np
np.set_printoptions(threshold=sys.maxsize)
import re
import os
os.chdir('D:\data\kadaster')

# =============================================================================
#                           INLEZEN INPUT FILE
# =============================================================================

jaartal = '2022'
col_names = ['provincie', 'jaartal', 'eigendom_id', 'naam', 'identificatie', 'landcode', 'postcode', 'gemeente', 'straatnaam', 'huisbis', 'subadres', 'volgorde', 'recht', 'type_persoon'] # Definieer de headers (N.B. type_persoon is in 2023 type_eigenaar).
na_values = ['NaN', '', 'NULL', 'null']
df = pd.read_csv(jaartal + '\KAD_' + jaartal + '_alle_eigenaars.txt', delimiter='\t', encoding='latin-1', names=col_names, header=0, quotechar='"', quoting=3, engine='python',
                            dtype={'provincie':'string', 'jaartal':'Int64', 'eigendom_id':'Int64', 'naam':'string', 'identificatie':'string', 'landcode':'string', 'postcode':'string',
                                   'gemeente':'string', 'straatnaam':'string', 'huisbis':'string','subadres':'string', 'volgorde':'Int64', 'recht':'string', 'type_persoon':'string'},
                            keep_default_na = False, na_values = na_values) # Zet de default missing values op 'False' (want 'NA' bestaat ook als landcode)

# =============================================================================
#                               BASISAFSPRAKEN
# =============================================================================

# Definieer het aantal eigenaars per eigendom_id en voeg dit toe aan de dataframe.
df = df.assign(aantal_eigenaars = df['eigendom_id'].map(df['eigendom_id'].value_counts()))

# Recode landcode into belgisch_eigenaar (1= Belgisch, 2 = buitenlands, 3 = onbekend)
df['belgisch_eigenaar'] = df['landcode'].replace('BE', '1').fillna('3') # Remaining = buitenland = assign value 2
df['belgisch_eigenaar'] = df['belgisch_eigenaar'].apply(lambda x: x if ((x == '1') | (x == '3')) else '2')

# =============================================================================
#                               PROCESS RECHT
# =============================================================================

df['right_verdeelsleutel'] = df['recht']
df['right_verdeelsleutel'] = df['right_verdeelsleutel'].replace('(', '') # Remove '('
df['right_verdeelsleutel'] = df['right_verdeelsleutel'].map(lambda x: x.lstrip('-').rstrip('-'), na_action='ignore') # Verwijder '-' aan het begin en einde van de string
df['right_verdeelsleutel'] = df['right_verdeelsleutel'].map(lambda x: x.lstrip(' ').rstrip(' '), na_action='ignore') # Verwijder spaties aan het begin en einde van de string
df['right_verdeelsleutel'] = df['right_verdeelsleutel'].replace(np.nan,'') # Vervang NaN naar lege strings (zoniet zal RegEx een TypeError genereren)

lijst_omschrijving1, lijst_teller1, lijst_noemer1 = list(), list(), list()
lijst_omschrijving2, lijst_teller2, lijst_noemer2 = list(), list(), list()
#lengte = list()

for element in df['right_verdeelsleutel']:
    
# =============================================================================
#           BEREKEN TELLER(S), NOEMER(S) EN BESCHRIJVING(EN)
# =============================================================================

    fractions = re.findall(r'(\d+)/(\d+)', element) # Zoek de breuk(en) binnen de cel
    txt_between_fractions = re.findall(r'(\b\D*)(?:\s?\d+/\d+)', element) # Zoek naar non-numerieke tekst vóór de breuken
    #lengte.append(len(fractions)) # Archiveer om te na te gaan hoeveel breuken er in één veld aanwezig kunnen zijn
    
    if len(fractions) > 0:
        
        # Definieer de default values (d.w.z. indien ze niet aanwezig zouden zijn)
        omschrijving1 = ''
        teller1 = np.nan 
        noemer1 = np.nan 
        omschrijving2 = ''
        teller2 = np.nan 
        noemer2 = np.nan
        
        # Genereer de overeenkomstige omschrijvingen, tellers en noemers (kan nog uitgebreid worden naargelang het maximale aantal breuken)
        for i in range(len(fractions)):
            
            if len(fractions) == 1: # Indien er één breuk aanwezig is, neem dan mogelijks aanwezige tekst na deze breuk op als omschrijving 2 
                chars_after_first_fraction = re.findall(r'\d+/\d+(\D+)', element)
                if len(chars_after_first_fraction) > 0:
                    omschrijving2 = chars_after_first_fraction[0].strip().strip('-') # Verwijder spaties en dashes aan het begin en einde van de string
                
            if i == 0: 
                teller1 = int(fractions[i][0])
                noemer1 = int(fractions[i][1])
                omschrijving1 = txt_between_fractions[i].strip().strip('-') # Verwijder spaties en dashes aan het begin en einde van de string
            
            elif i == 1:
                teller2 = int(fractions[i][0])
                noemer2 = int(fractions[i][1])
                omschrijving2 = txt_between_fractions[i].strip().strip('-')
        
        lijst_omschrijving1.append(omschrijving1)
        lijst_teller1.append(teller1)
        lijst_noemer1.append(noemer1)
        lijst_omschrijving2.append(omschrijving2)
        lijst_teller2.append(teller2)
        lijst_noemer2.append(noemer2)
                
    else:
        lijst_omschrijving1.append(element) # Neem het volledige veld over in het geval er geen breuk aanwezig is
        lijst_teller1.append(np.nan)
        lijst_noemer1.append(np.nan)
        lijst_omschrijving2.append('')
        lijst_teller2.append(np.nan)
        lijst_noemer2.append(np.nan)         
        
#print(max(lengte)) #N.B. voor 2023 zijn er tot 6 breuken aanwezig

# Voeg de resultaten toe aan de main dataframe
zakelijke_rechten = pd.DataFrame({'omschrijving1':np.array(lijst_omschrijving1), 'teller1':np.array(lijst_teller1), 'noemer1':np.array(lijst_noemer1),
                                  'omschrijving2':np.array(lijst_omschrijving2), 'teller2':np.array(lijst_teller2), 'noemer2':np.array(lijst_noemer2)})
df = pd.concat([df, zakelijke_rechten], axis="columns") # merk op: concat is doorgaans sneller dan join

# Toon het resultaat van een specifieke rechtsleutel
#df.loc[df['right_verdeelsleutel'] == 'VE VR 20CA VE 1/3 VG 2/3 VR 01A 85CA'] 
#df[['eigendom_id', 'identificatie', 'right_verdeelsleutel', 'omschrijving1', 'teller1', 'noemer1', 'omschrijving2', 'teller2', 'noemer2']].to_csv('werkbestanden_python/verwerken_recht/python_' + jaartal + '.csv', index = False)

# Maak opslag vrij
del omschrijving1, teller1, noemer1, omschrijving2, teller2, noemer2
del lijst_omschrijving1, lijst_teller1, lijst_noemer1, lijst_omschrijving2, lijst_teller2, lijst_noemer2
del chars_after_first_fraction, element, fractions, i, txt_between_fractions
del zakelijke_rechten

# Onderscheid welke omschrijvingen we wel/niet meenemen. De parameters staan gecentraliseerd in het Excel-bestand 'kadaster_parameters'. Wijzigingen moeten dus hierin worden doorgevoerd.
overzicht_omschrijvingen = pd.read_excel('kadaster_parameters.xlsx', sheet_name='omschrijving')
omschrijvingen = np.array(overzicht_omschrijvingen['omschrijvingen'])
df[['omschrijving1_clean', 'omschrijving2_clean']] = df[['omschrijving1', 'omschrijving2']] # Maak een kopie van de omschrijvingen 
df['omschrijving1_clean'] = df['omschrijving1_clean'].map(lambda x: 'VERP' if x == 'VR' else x) # Toegevoegd na vergelijking met SPSS
df['omschrijving2_clean'] = df['omschrijving2_clean'].map(lambda x: 'VERP' if x == 'VR' else x)
df['omschrijving1_clean'] = df['omschrijving1_clean'].map(lambda x: x if x in omschrijvingen else '') # Behoud enkel de omschrijvingen die aanwezig zijn in het Excelbestand
df['omschrijving2_clean'] = df['omschrijving2_clean'].map(lambda x: x if x in omschrijvingen else '')

# Corrigeer voor een mogelijks valide omschrijving vóór de eerste spatie/dash.
df[['omschrijving1_temp', 'omschrijving2_temp']] = ''
#test = df.loc[(df['omschrijving1_clean'] == '') & (df['omschrijving1'].str.contains('-'))]
df['omschrijving1_temp'] = np.where((df['omschrijving1_clean']=='') & (df['omschrijving1'].str.contains(' ')),
                                    df['omschrijving1'].str.split().str[0], 
                                    df['omschrijving1_temp'])
df['omschrijving1_temp'] = np.where((df['omschrijving1_temp']=='') & (df['omschrijving1_clean']=='') & (df['omschrijving1'].str.contains('-')), # Geef spaties voorrang op '-' (anders wordt dit overschreven)
                                    df['omschrijving1'].str.split('-').str[0],
                                    df['omschrijving1_temp'])
df['omschrijving2_temp'] = np.where((df['omschrijving2_clean']=='') & (df['omschrijving2'].str.contains(' ')),
                                    df['omschrijving2'].str.split().str[0],
                                    df['omschrijving2_temp'])
df['omschrijving2_temp'] = np.where((df['omschrijving2_temp']=='') & (df['omschrijving2_clean']=='') & (df['omschrijving2'].str.contains('-')),
                                    df['omschrijving2'].str.split('-').str[0],
                                    df['omschrijving2_temp'])


# Verander 'VR' naar 'VERP' in de temp velden
df['omschrijving1_temp'] = df['omschrijving1_temp'].map(lambda x: 'VERP' if x == 'VR' else x)
df['omschrijving2_temp'] = df['omschrijving2_temp'].map(lambda x: 'VERP' if x == 'VR' else x)

# Controleer of we de beschrijvingen in de temporary kolom al dan niet meenemen. Indien wel, plaats ze in de juiste kolom (omschrijving#_clean)
df['omschrijving1_clean'] = np.where((df['omschrijving1_clean']=='') & (df['omschrijving1_temp'].isin(omschrijvingen)), df['omschrijving1_temp'], df['omschrijving1_clean'])
df['omschrijving2_clean'] = np.where((df['omschrijving2_clean']=='') & (df['omschrijving2_temp'].isin(omschrijvingen)), df['omschrijving2_temp'], df['omschrijving2_clean'])
#test = df.loc[df['eigendom_id'] == 3100503]

# Bepaal welke tellers en noemers we wel/niet meenemen naargelang het soort beschrijving (zie Excel). 1 = meenemen, 0 = niet meenemen.
recoding_dict = pd.Series(overzicht_omschrijvingen.meenemen.values,index=overzicht_omschrijvingen.omschrijvingen).to_dict()
df['meenemen_teller1'] = df['omschrijving1_clean'].map(recoding_dict) # Omschrijvingen die niet in de Excel gedefinieerd worden, worden omgezet naar NA values.
df['meenemen_teller2'] = df['omschrijving2_clean'].map(recoding_dict)

# Wat nemen we expliciet mee? N.B. zet de noemer ook op 0 in het geval de teller op 0 wordt gezet (om geen fouten te genereren bij het delen later)
df['eigendom_teller'] = np.where(df['meenemen_teller1'] == 1, df['teller1'],
                                 np.where(df['meenemen_teller1'] == 0, 0, np.nan))
df['eigendom_noemer'] = np.where(df['meenemen_teller1'] == 1, df['noemer1'],
                                 np.where(df['meenemen_teller1'] == 0, 1, np.nan))
df['eigendom_teller2'] = np.where(df['meenemen_teller2'] == 1, df['teller2'],
                                  np.where(df['meenemen_teller2'] == 0, 0, np.nan))
df['eigendom_noemer2'] = np.where(df['meenemen_teller2'] == 1, df['noemer2'],
                                  np.where(df['meenemen_teller2'] == 0, 1, np.nan))

# Indien er geen breuk kan worden gevormd, gaan we ervan uit dat de omschrijving op de hele eigendom staat
df['eigendom_teller'] = np.where((df['meenemen_teller1']==1) & (pd.isna(df['teller1'])), 1, df['eigendom_teller'])
df['eigendom_noemer'] = np.where((df['meenemen_teller1']==1) & (pd.isna(df['noemer1'])), 1, df['eigendom_noemer'])
df['eigendom_teller2'] = np.where((df['meenemen_teller2']==1) & (pd.isna(df['teller2'])), 1, df['eigendom_teller2'])
df['eigendom_noemer2'] = np.where((df['meenemen_teller2']==1) & (pd.isna(df['noemer2'])), 1, df['eigendom_noemer2'])

# Bereken de breuk
df['aandeel_eigendom'] = df['eigendom_teller']/df['eigendom_noemer']
df['aandeel_eigendom'] = np.where((df['eigendom_teller2']/df['eigendom_noemer2']) > 0,
                                  df['aandeel_eigendom']+(df['eigendom_teller2']/df['eigendom_noemer2']),
                                  df['aandeel_eigendom'])
df['aandeel_eigendom'] = np.where(pd.isna(df['aandeel_eigendom']), df['eigendom_teller2']/df['eigendom_noemer2'], df['aandeel_eigendom'])

# Als mensen meer dan 100% eigenaar zijn, ronden we af naar 100%.
df['aandeel_eigendom'] = np.where(df['aandeel_eigendom'] > 1, 1, df['aandeel_eigendom'])

# We testen het resultaat
df['som_aandelen'] = df.groupby('eigendom_id')['aandeel_eigendom'].transform('sum', min_count=1)
df['aantal_eigenaars'] = df.groupby('eigendom_id')['eigendom_id'].transform('count') # Idem als in deel 1 van het script

# Indien het resultaat niet OK is, maar er is maar één eigenaar gekend, dan geven we die eigenaar de volledige eigendom
df['aandeel_eigendom'] = np.where((df['aantal_eigenaars']==1) & ((df['som_aandelen'] == 0) | (pd.isna(df['som_aandelen']))),
                                  1, df['aandeel_eigendom'])
# Wanneer er geen breuken beschikbaar zijn, maar er is wel info dat iemand verpacht, dan geven we die de volledige eigendom
df['aandeel_eigendom'] = np.where((df['som_aandelen'] == 0) & ((df['omschrijving1'] == 'VERP') | (df['omschrijving1'] == 'VERP DEEL')),
                                  1, df['aandeel_eigendom'])

# We controleren opnieuw (bv. eigendom_id 209171722 heeft een som_aandelen = 2 ~ hiervoor moet ook nog gecorrigeerd worden)
df['som_aandelen'] = df.groupby('eigendom_id')['aandeel_eigendom'].transform('sum', min_count=1)
#test = df.loc[df['som_aandelen'] < 1]
#test = df.loc[pd.isna(df['som_aandelen'])]
#df['som_aandelen'].median()

# Potentiële eigenaars meenemen
df['potentiele_eigenaar'] = np.where(pd.isna(df['aandeel_eigendom']), 1, np.nan)
df['som_aandelen'] = df.groupby('eigendom_id')['aandeel_eigendom'].transform('sum', min_count=1) # Niet meer nodig
df['som_potentiele_eigenaar'] = df.groupby('eigendom_id')['potentiele_eigenaar'].transform('sum', min_count = 1) # Indien enkel NaN values in potentiele_eigenaar, genereer dan ook een NaN value.

# We voeren een correctie uit op het veld aandeel_eigendom (i.e. we corrigeren voor een som_aandelen > 1). 
df['aandeel_eigendom'] = df['aandeel_eigendom'] / df['som_aandelen']
# Indien de som van de aandelen 0 is, dan wordt in bovenstaande bewerking een NaN value toegewezen. We corrigeren dit, indien mogelijk, door middel van de potentiële eigenaars.
df['aandeel_eigendom'] = np.where(((pd.isna(df['som_aandelen'])) | (df['som_aandelen'] == 0)) & (pd.isna(df['aandeel_eigendom'])) & (df['potentiele_eigenaar'] == 1),
                                  1/df['som_potentiele_eigenaar'], df['aandeel_eigendom'])

# Herbereken voor de laatste keer de som van de aandelen. Maak een histogram om meer zicht te krijgen op dit veld.
df['som_aandelen'] = df.groupby('eigendom_id')['aandeel_eigendom'].transform('sum', min_count=1)
df['som_aandelen'].isnull().sum() # Er zijn 9 extra velden in som_aandelen gelijk aan NaN (i.e. 7469 cases in Python, 7460 in SPSS). Controleer voor welke eigendommen dit het geval is.
print(df['som_aandelen'].min(), df['som_aandelen'].max(), df['som_aandelen'].mean())

# Vergelijk met SPSS output
#df.to_feather('werkbestanden_python/verwerken_recht/output/python_' + jaartal + '.feather')

# =============================================================================
#                       REDUCTIE DATAFRAME EN EXPORT
# =============================================================================

# Drop/remove de kolommen die niet vereist zijn in de output file
df = df.drop(['aantal_eigenaars', 'right_verdeelsleutel', 'omschrijving1', 'omschrijving2', 'omschrijving1_temp', 'omschrijving2_temp', 'meenemen_teller1',
         'meenemen_teller2', 'eigendom_teller', 'eigendom_noemer', 'eigendom_teller2', 'eigendom_noemer2', 'som_aandelen', 'potentiele_eigenaar', 'som_potentiele_eigenaar'], axis=1)
df = df.rename(columns={'omschrijving1_clean': 'omschrijving1', 'omschrijving2_clean': 'omschrijving2'})

# Herschik de kolommen en sorteer de dataframe op eigendom_id
df = df.reindex(columns = ['provincie', 'jaartal', 'eigendom_id', 'naam', 'identificatie', 'landcode', 'postcode', 'gemeente', 'straatnaam', 'huisbis', 'subadres', 'volgorde',
                           'recht', 'type_persoon', 'aandeel_eigendom', 'belgisch_eigenaar', 'omschrijving1', 'teller1', 'noemer1', 'omschrijving2', 'teller2', 'noemer2'])
df = df.sort_values(by=['eigendom_id'], ignore_index=True)

# Exporteer het resultaat naar een feather bestand (voorkeur) en een csv-bestand
df.to_feather('werkbestanden_python/basisafspraken_alle_eigenaars_' + jaartal + '.feather') # Gebruik geen back slash (dit veroorzaakt een invalid argument error)
#df.to_csv('werkbestanden_python/basisafspraken_alle_eigenaars_' + jaartal + '.csv') # Duurt beduidend langer

# =============================================================================
# Opmerking: er zitten nog een aantal optimalisaties/verbeteringen in de pijplijn.
# =============================================================================
