# -*- coding: utf-8 -*-
"""
Created on Mon Oct 23 16:23:43 2023

"""

# =============================================================================
#                             CONFIGURATIE
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
df['stat_sector'] = df['stat_sector'].astype('string') # Transformeer expliciet naar 'string', gezien we anders errors krijgen bij de groupby

# =============================================================================
#           LUIK 5: PLATTE ONDERWERPEN - INTEGRATIE NAAR SWING
# =============================================================================

df['LUIK5'] = np.nan

# WOONGELEGENHEDEN 

# In individuele woningen, appartementen en collectieven
df['v2210_wa_indiv'] = np.where(df['type_woonaanbod'] == 1, df['woongelegenheden'], np.nan)
df['v2210_wa_app'] = np.where(df['type_woonaanbod'] == 2, df['woongelegenheden'], np.nan)
df['v2210_wa_coll'] = np.where(df['type_woonaanbod'] == 3, df['woongelegenheden'], np.nan)

# Indicatoren eengezins/meergezinswoningen. Al deze indicatoren kunnen eenvoudig opgeteld worden.
df['v2210_wv_eengezinswoningen'] = np.where(df['eengezin_meergezin'] == 1, df['woongelegenheden'], np.nan)
df['v2210_wv_meergezinswoningen'] = np.where(df['eengezin_meergezin'] == 2, df['woongelegenheden'], np.nan)
df['v2210_wv_mg_2_5'] = np.where((df['eengezin_meergezin'] == 2) & (df['woongelegenheden_perceel_tot'] <= 5), df['woongelegenheden'], np.nan)
df['v2210_wv_mg_6_10'] = np.where((df['eengezin_meergezin'] == 2) & (df['woongelegenheden_perceel_tot'] > 5) & (df['woongelegenheden_perceel_tot'] <= 10),
                                  df['woongelegenheden'], np.nan)
df['v2210_wv_mg_11p'] = np.where((df['eengezin_meergezin'] == 2) & (df['woongelegenheden_perceel_tot'] > 10), df['woongelegenheden'], np.nan)

# Strikt gezien niet nodig: teller aantal teruggevonden huishoudens
df['v2210_huishoudens'] = df['huidig_bewoond']

# BOUWJAAR

# Indicatoren bouwjaar (enkel bij woongelegenheden, op basis van woonvoorraad). Al deze indicatoren kunnen eenvoudig opgeteld worden.
df['v2210_wv_bj_voor1900'] = np.where(df['bouwjaar_cat_wgl'] == 1, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_1900_1918'] = np.where(df['bouwjaar_cat_wgl'] == 2, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_1919_1930'] = np.where(df['bouwjaar_cat_wgl'] == 3, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_1931_1945'] = np.where(df['bouwjaar_cat_wgl'] == 4, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_1946_1960'] = np.where(df['bouwjaar_cat_wgl'] == 5, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_1961_1970'] = np.where(df['bouwjaar_cat_wgl'] == 6, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_1971_1980'] = np.where(df['bouwjaar_cat_wgl'] == 7, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_1981_1990'] = np.where(df['bouwjaar_cat_wgl'] == 8, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_1991_2000'] = np.where(df['bouwjaar_cat_wgl'] == 9, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_2001_2010'] = np.where(df['bouwjaar_cat_wgl'] == 10, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_2011_2020'] = np.where(df['bouwjaar_cat_wgl'] == 11, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_2021_2030'] = np.where(df['bouwjaar_cat_wgl'] == 12, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_onbekend'] = np.where(df['bouwjaar_cat_wgl'] == 13, df['woongelegenheden'], np.nan)
df['v2210_wv_bj_2015p'] = np.where(df['bouwjaar_clean'] >= 2015, df['woongelegenheden'], np.nan)

# LAATSTE WIJZIGING

# Indicatoren laatste wijziging (enkel bij woongelegenheden, op basis van woonvoorraad). Al deze indicatoren kunnen eenvoudig opgeteld worden.
df['v2210_wv_lw_1983_1990'] = np.where(df['laatste_wijziging_cat_wgl'] == 8, df['woongelegenheden'], np.nan)
df['v2210_wv_lw_1991_2000'] = np.where(df['laatste_wijziging_cat_wgl'] == 9, df['woongelegenheden'], np.nan)
df['v2210_wv_lw_2001_2010'] = np.where(df['laatste_wijziging_cat_wgl'] == 10, df['woongelegenheden'], np.nan)
df['v2210_wv_lw_2011_2020'] = np.where(df['laatste_wijziging_cat_wgl'] == 11, df['woongelegenheden'], np.nan)
df['v2210_wv_lw_2021_2030'] = np.where(df['laatste_wijziging_cat_wgl'] == 12, df['woongelegenheden'], np.nan)
df['v2210_wv_lw_onbekend'] = np.where(df['laatste_wijziging_cat_wgl'] == 13, df['woongelegenheden'], np.nan)
df['v2210_wv_lw_2015p'] = np.where(df['laatste_wijziging_clean'] >= 2015, df['woongelegenheden'], np.nan)

# Platte onderwerpen recentste jaar
df['v2210_wgl_lwbj_1983_1990'] = np.where((df['recentste_jaar'] >= 1983) & (df['recentste_jaar'] <= 1990), df['woongelegenheden'], np.nan)
df['v2210_wgl_lwbj_1991_2000'] = np.where((df['recentste_jaar'] >= 1991) & (df['recentste_jaar'] <= 2000), df['woongelegenheden'], np.nan)
df['v2210_wgl_lwbj_2001_2010'] = np.where((df['recentste_jaar'] >= 2001) & (df['recentste_jaar'] <= 2010), df['woongelegenheden'], np.nan)
df['v2210_wgl_lwbj_2011_2020'] = np.where((df['recentste_jaar'] >= 2011) & (df['recentste_jaar'] <= 2020), df['woongelegenheden'], np.nan)
df['v2210_wgl_lwbj_2021_2030'] = np.where(df['recentste_jaar'] >= 2021, df['woongelegenheden'], np.nan)
df['v2210_wgl_lwbj_1983p'] = np.where(df['recentste_jaar'] >= 1983, df['woongelegenheden'], np.nan)
df['v2210_wgl_lwbj_2015p'] = np.where(df['recentste_jaar'] >= 2015, df['woongelegenheden'], np.nan)

# Voorbereiding
df.rename(columns={'stat_sector':'geoitem'}, inplace=True)

# We aggregeren op STATSEC NIVEAU
column_trans = {'woongelegenheden': 'v2210_woonvoorraad',
        'wgl_woonfunctie': 'v2210_woonaanbod',
        'v2210_wa_indiv': 'v2210_wa_indiv',
        'v2210_wa_app': 'v2210_wa_app', 
        'v2210_wa_coll': 'v2210_wa_coll', 
        'v2210_wv_eengezinswoningen': 'v2210_wv_eengezinswoningen', 
        'v2210_wv_meergezinswoningen': 'v2210_wv_meergezinswoningen', 
        'v2210_wv_mg_2_5': 'v2210_wv_mg_2_5', 
        'v2210_wv_mg_6_10': 'v2210_wv_mg_6_10', 
        'v2210_wv_mg_11p': 'v2210_wv_mg_11p', 
        'v2210_huishoudens': 'v2210_huishoudens', 
        'hurende_huishoudens': 'v2210_huurders', 
        'inwonend_eigenaarsgezin': 'v2210_inwonend_eigenaarsgezin', 
        'bewoning_zonder_link': 'v2210_hh_onbekend', 
        'v2210_wv_bj_voor1900': 'v2210_wv_bj_voor1900', 
        'v2210_wv_bj_1900_1918': 'v2210_wv_bj_1900_1918', 
        'v2210_wv_bj_1919_1930': 'v2210_wv_bj_1919_1930', 
        'v2210_wv_bj_1931_1945': 'v2210_wv_bj_1931_1945', 
        'v2210_wv_bj_1946_1960': 'v2210_wv_bj_1946_1960', 
        'v2210_wv_bj_1961_1970': 'v2210_wv_bj_1961_1970', 
        'v2210_wv_bj_1971_1980': 'v2210_wv_bj_1971_1980', 
        'v2210_wv_bj_1981_1990': 'v2210_wv_bj_1981_1990', 
        'v2210_wv_bj_1991_2000':  'v2210_wv_bj_1991_2000', 
        'v2210_wv_bj_2001_2010': 'v2210_wv_bj_2001_2010', 
        'v2210_wv_bj_2011_2020': 'v2210_wv_bj_2011_2020', 
        'v2210_wv_bj_onbekend': 'v2210_wv_bj_onbekend', 
        'v2210_wv_lw_1983_1990': 'v2210_wv_lw_1983_1990', 
        'v2210_wv_lw_1991_2000': 'v2210_wv_lw_1991_2000', 
        'v2210_wv_lw_2001_2010': 'v2210_wv_lw_2001_2010', 
        'v2210_wv_lw_2011_2020': 'v2210_wv_lw_2011_2020', 
        'v2210_wv_lw_onbekend': 'v2210_wv_lw_onbekend', 
        'v2210_wgl_lwbj_1983_1990': 'v2210_wgl_lwbj_1983_1990', 
        'v2210_wgl_lwbj_1991_2000': 'v2210_wgl_lwbj_1991_2000', 
        'v2210_wgl_lwbj_2001_2010': 'v2210_wgl_lwbj_2001_2010', 
        'v2210_wgl_lwbj_2011_2020': 'v2210_wgl_lwbj_2011_2020', 
        'v2210_wgl_lwbj_1983p': 'v2210_wgl_lwbj_1983p', 
        'egw_open_bouwvorm': 'v2210_open', 
        'egw_halfopen_bouwvorm': 'v2210_halfopen', 
        'egw_gesloten_bouwvorm': 'v2210_gesloten', 
        'egw_andere_bouwvorm': 'v2210_egw_andere', 
        'v2210_wv_bj_2015p': 'v2210_wv_bj_2015p', 
        'v2210_wv_lw_2015p': 'v2210_wv_lw_2015p', 
        'v2210_wgl_lwbj_2015p': 'v2210_wgl_lwbj_2015p', 
        'v2210_wv_bj_2021_2030': 'v2210_wv_bj_2021_2030', 
        'v2210_wv_lw_2021_2030': 'v2210_wv_lw_2021_2030', 
        'v2210_wgl_lwbj_2021_2030': 'v2210_wgl_lwbj_2021_2030'}


columns_to_sum = list(column_trans.keys())
aggr = df.groupby('geoitem')[columns_to_sum].sum(min_count=1).reset_index() # Als alle values binnen een group NaN zijn, geef dan ook NaN weer en niet 0
aggr.columns = ['geoitem'] + list(column_trans.values())
del df

# Lees de verwerkte gebiedsniveaus in. Selecteer de statsec en het bijhorende gewest. Hang het gewest aan de main dataframe (aggr)
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
#                    FORMAT NAAR RICHTLIJNEN PINC
# =============================================================================

# REGEL 1 = indien gebied onbekend: enkel inlezen indien nodig. Alle zinloze waarden vervangen we door -99996
columns_to_change = list(column_trans.values())
for col in columns_to_change:
    aggr[col] = np.where((aggr['geoitem'].str.contains('ZZZZ')) & ((aggr[col] == 0) | (pd.isna(aggr[col]))), -99996, aggr[col])

# REGEL 2 = indien Brussel: ALLES is een ontbrekende waarde: -99999 (TOGA)
for col in columns_to_change:
    aggr[col] = np.where(aggr['gewest'] == 4000, -99999, aggr[col])

# REGEL 3 = indien in een niet-onbekende statsec (geen 'ZZZZ' en gewest = 2000): verander missing values naar 0
# Na het toepassen van deze regel zou het onmogelijk moeten zijn dat er nog velden zijn met een sysmis
for col in columns_to_change:
    aggr[col] = np.where((~aggr['geoitem'].str.contains('ZZZZ')) & (aggr['gewest'] == 2000) & (pd.isna(aggr[col])), 0, aggr[col])

del aggr['gewest']

# =============================================================================
#                                EXPORT
# =============================================================================

aggr.to_excel('upload/' + jaartal + '/pinc_basis_plat_' + jaartal + '.xlsx', sheet_name = 'pinc_basis_plat_' + jaartal, index = False)


