# -*- coding: utf-8 -*-
"""
Created on Wed Oct 25 16:15:53 2023

"""

# =============================================================================
#                               CONFIGURATIE
# =============================================================================

# Encoding = windows-1252, in ANSI Latin 1
# Importeer de nodige modules en declarereer de main directory
import pandas as pd
pd.set_option('display.max.columns', None)
import sys
import numpy as np
np.set_printoptions(threshold=sys.maxsize)
import os
os.chdir('D:\data\kadaster')
#import pyreadstat

# =============================================================================
#                               PARAMETERS
# =============================================================================

jaartal = '2018'

# =============================================================================
#                       INLEZEN VAN INPUT FILE
# =============================================================================

# Inlezen van de opgekuiste eigendommen
df = pd.read_feather('werkbestanden_python/eigendom_' + jaartal + '_basisafspraken.feather')
df['nis_indeling'].fillna('', inplace=True)
df['stat_sector'] = df['stat_sector'].astype('string')

# =============================================================================
#                           CONFIGURATIE
# =============================================================================

nis_dict = {
    '1A': 'v2210_lgb_1AE',
    '1B':'v2210_lgb_1BC',
    '1C': 'v2210_lgb_1BC',
    '1D': 'v2210_lgb_1DI',
    '1E': 'v2210_lgb_1AE',
    '1F': 'v2210_lgb_1F',
    '1G': 'v2210_lgb_1G',
    '1H': 'v2210_lgb_1H',
    '1I': 'v2210_lgb_1DI',
    '1J': 'v2210_lgb_1J',
    '1K': 'v2210_lgb_1K',
    '1L': 'v2210_lgb_1L',
    '1M': 'v2210_lgb_1MNOP',
    '1N': 'v2210_lgb_1MNOP',
    '1O': 'v2210_lgb_1MNOP',
    '1P': 'v2210_lgb_1MNOP',
    '2A1': 'v2210_lgb_2A1A2',
    '2A2': 'v2210_lgb_2A1A2',
    '2B': 'v2210_lgb_2B',
    '2C': 'v2210_lgb_2C',
    '2D': 'v2210_lgb_2DEF',
    '2E': 'v2210_lgb_2DEF',
    '2F': 'v2210_lgb_2DEF',
    '2G': 'v2210_lgb_2G',
    '2H': 'v2210_lgb_2H',
    '2I': 'v2210_lgb_2I',
    '2J': 'v2210_lgb_2JK',
    '2K': 'v2210_lgb_2JK',
    '2L': 'v2210_lgb_2L',
    '2M': 'v2210_lgb_2M',
    '2N': 'v2210_lgb_2N',
    '2O': 'v2210_lgb_2O',
    '2P': 'v2210_lgb_2P',
    '2Q': 'v2210_lgb_2Q',
    '2R': 'v2210_lgb_2RST',
    '2S': 'v2210_lgb_2RST',
    '2T': 'v2210_lgb_2RST'
    }

df[list(nis_dict.values())] = np.nan # We maken eerst de nieuwe kolommen aan
nis_indeling_overzicht = list(nis_dict.keys())

for nis_indeling in nis_indeling_overzicht:
    df[nis_dict[nis_indeling]] = np.where(df['nis_indeling'] == nis_indeling, df['surface_total'], df[nis_dict[nis_indeling]])

df.rename(columns={'stat_sector':'geoitem', 'jaartal': 'period'}, inplace=True)

# Aggregeer op period, capakey en geoitem en neem binnen de groep het maximum van de verdiepen (inc. dakverdiep)
agg0 = df.groupby(['period', 'capakey', 'geoitem']).verdiepen_inc_dakverdiep.agg(['max']).reset_index()
agg0.rename(columns={'max':'verdiepen_inc_dakverdiep_max'}, inplace = True)
agg0 = agg0[agg0.verdiepen_inc_dakverdiep_max > -1]

# Aggregeer deze dataframe vervolgens op period en geoitem
# Neem binnen de groep de som van de verdiepen_inc_dakverdiep_max en bereken de aantallen per groep
aggverd = agg0.groupby(['period', 'geoitem']).verdiepen_inc_dakverdiep_max.agg(['sum', 'count']).reset_index()
aggverd.rename(columns={'sum': 'v2210_som_verdiepen', 'count': 'v2210_prc_met_verdiepteller'}, inplace = True)
del agg0

# Aggregeer eigendommen op geoitem en period en sommeer een reeks variabelen
aggr = df.groupby(['geoitem', 'period'])['v2210_aantal_kamers', 'v2210_wgl_met_kamers', 'v2210_woning_met_kamers', 
                                         'v2210_woonoppervlakte', 'v2210_wooneenheid_opp', 'v2210_wgl_opp', 
                                         'v2210_lgb_1AE', 'v2210_lgb_1BC', 'v2210_lgb_1DI', 'v2210_lgb_1F', 
                                         'v2210_lgb_1G', 'v2210_lgb_1H', 'v2210_lgb_1J', 'v2210_lgb_1K', 'v2210_lgb_1L', 
                                         'v2210_lgb_1MNOP', 'v2210_lgb_2A1A2', 'v2210_lgb_2B', 'v2210_lgb_2C', 
                                         'v2210_lgb_2DEF', 'v2210_lgb_2G', 'v2210_lgb_2H', 'v2210_lgb_2I', 'v2210_lgb_2JK', 
                                         'v2210_lgb_2L', 'v2210_lgb_2M', 'v2210_lgb_2N', 'v2210_lgb_2O', 'v2210_lgb_2P', 
                                         'v2210_lgb_2Q', 'v2210_lgb_2RST'].sum(min_count=1).reset_index()

# Hang de dataframes aan elkaar
aggr = pd.merge(aggr, aggverd, on = ['geoitem', 'period'], how = 'left')
del aggverd, df

# Lees de verwerkte gebiedsniveaus in. Selecteer de statsec en het bijhorende gewest. Hang het gewest aan onze main dataframe (aggr)
allegebieden = pd.read_excel('gebiedsniveaus/verzamelbestanden/verwerkt_alle_gebiedsniveaus.xlsx')
uniekstatsec = allegebieden.groupby(['statsec', 'gewest']).size().reset_index(name='N_BREAK')
del allegebieden
del uniekstatsec['N_BREAK']
uniekstatsec.rename(columns={'statsec': 'geoitem'}, inplace=True)
uniekstatsec['geoitem'] = uniekstatsec['geoitem'].astype('string')
aggr = pd.merge(aggr,uniekstatsec,on='geoitem', how='outer')
aggr.sort_values(by=['geoitem'],ignore_index=True, inplace = True)
del uniekstatsec

# Dit is enkel nodig omdat dit missing is voor de lege sectoren
aggr['period'] = int(jaartal)
aggr['geolevel'] = 'statsec'

# In SPSS is er extra code om de decimalen niet weer te geven. In Python is dit reeds automatisch gebeurd.

# =============================================================================
#                       FORMAT NAAR RICHTLIJNEN PINC
# =============================================================================

# REGEL 1 = indien gebied onbekend: enkel inlezen indien nodig. Alle zinloze waarden vervangen we door -99996
columns = ['v2210_aantal_kamers', 'v2210_wgl_met_kamers', 'v2210_woning_met_kamers', 'v2210_woonoppervlakte', 'v2210_wooneenheid_opp', 'v2210_wgl_opp',  
           'v2210_som_verdiepen', 'v2210_prc_met_verdiepteller', 'v2210_lgb_1AE', 'v2210_lgb_1BC', 'v2210_lgb_1DI', 'v2210_lgb_1F', 'v2210_lgb_1G', 
           'v2210_lgb_1H', 'v2210_lgb_1J', 'v2210_lgb_1K', 'v2210_lgb_1L', 'v2210_lgb_1MNOP', 'v2210_lgb_2A1A2', 'v2210_lgb_2B', 'v2210_lgb_2C', 
           'v2210_lgb_2DEF', 'v2210_lgb_2G', 'v2210_lgb_2H', 'v2210_lgb_2I', 'v2210_lgb_2JK', 'v2210_lgb_2L', 'v2210_lgb_2M', 'v2210_lgb_2N',
           'v2210_lgb_2O', 'v2210_lgb_2P', 'v2210_lgb_2Q', 'v2210_lgb_2RST']

for col in columns:
    aggr[col] = np.where((aggr['geoitem'].str.contains('ZZZZ')) & ((aggr[col] == 0) | (pd.isna(aggr[col]))), -99996, aggr[col])

# REGEL 2 = indien Brussel: ALLES is een ontbrekende waarde: -99999 (TOGA)
for col in columns:
    aggr[col] = np.where(aggr['gewest'] == 4000, -99999, aggr[col])

# REGEL 3 = indien in een niet-onbekende statsec (geen 'ZZZZ' en gewest = 2000): verander missing values naar 0
# Na het toepassen van deze regel zou het onmogelijk moeten zijn dat er nog velden zijn met een sysmis
for col in columns:
    aggr[col] = np.where((~aggr['geoitem'].str.contains('ZZZZ')) & (aggr['gewest'] == 2000) & (pd.isna(aggr[col])), 0, aggr[col])
del aggr['gewest']

# =============================================================================
#                                   EXPORT
# =============================================================================

# Het jaartal kan niet bij tabbladtitel wegens te lang
aggr.to_excel('upload/' + jaartal + '/oppervlakte_hoogte_kamers_lgb' + jaartal + '.xlsx', sheet_name = 'oppervlakte_hoogte_kamers_lgb20', index = False) 



