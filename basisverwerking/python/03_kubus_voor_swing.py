# -*- coding: utf-8 -*-
"""
Created on Fri Oct 27 16:24:11 2023

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
#                         INLEZEN VAN INPUT FILE
# =============================================================================

# Inlezen van de opgekuiste eigendommen
df = pd.read_feather('werkbestanden_python/eigendom_' + jaartal + '_basisafspraken.feather')
df['nis_indeling'].fillna('', inplace=True)
df['stat_sector'] = df['stat_sector'].astype('string')

# =============================================================================
#                   LUIK 4: AGGREGATIE NAAR SWING KUBUS
# =============================================================================

# We werken met woongelegenheden
# En course de route hebben we al enkele variabelen gemaakt die rechtstreeks gebruikt kunnen worden als dimensieniveaus
# We hernoemen ze hier volgens de conventies voor kubusdimensieniveaus
df = df.rename(columns={'woonfunctie': 'v2210_woonfunctie',
                        'bouwjaar_cat': 'v2210_bouwjaar_cat',
                        'laatste_wijziging_cat': 'v2210_laatste_wijziging_cat', 
                        'eengezin_meergezin': 'v2210_eengezin_meergezin'})

# Aangepaste dimensies n.a.v. vergadering 20201016
df['v2210_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 1) & (df['soort_bebouwing'] == 'Open bebouwing'), 1, 0)
df['v2210_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 1) & (df['soort_bebouwing'] == 'Halfopen bebouwing'), 2, df['v2210_bouwvorm'])
df['v2210_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 1) & (df['soort_bebouwing'] == 'Gesloten bebouwing'), 3, df['v2210_bouwvorm'])
df['v2210_bouwvorm'] = np.where(df['v2210_eengezin_meergezin'] == 2, 4, df['v2210_bouwvorm'])

# Aangepaste dimensie n.a.v. issue 12
df['v2210_woningtype_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 1) & (df['soort_bebouwing'] == 'Open bebouwing'), 1, np.nan)
df['v2210_woningtype_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 1) & (df['soort_bebouwing'] == 'Halfopen bebouwing'), 2, df['v2210_woningtype_bouwvorm'])
df['v2210_woningtype_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 1) & (df['soort_bebouwing'] == 'Gesloten bebouwing'), 3, df['v2210_woningtype_bouwvorm'])
df['v2210_woningtype_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 1) & (pd.isna(df['v2210_woningtype_bouwvorm'])), 4, df['v2210_woningtype_bouwvorm'])
df['v2210_woningtype_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 2) & (df['woongelegenheden_perceel_tot'] <= 5), 5, df['v2210_woningtype_bouwvorm'])
df['v2210_woningtype_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 2) & (df['woongelegenheden_perceel_tot'] > 5) & (df['woongelegenheden_perceel_tot'] <= 10),
                                           6, df['v2210_woningtype_bouwvorm'])
df['v2210_woningtype_bouwvorm'] = np.where((df['v2210_eengezin_meergezin'] == 2) & (df['woongelegenheden_perceel_tot'] > 10), 7, df['v2210_woningtype_bouwvorm'])

# Verwijder wat niet nodig is
# Verwijder bewoning zonder link eerst
# Hou enkel woongelegenheden > 0 over
subset = df[(df['woongelegenheden'] > 0) & (pd.isna(df['bewoning_zonder_link']))]
subset = subset[['jaartal', 'capakey', 'eigendom_id', 'wooneenheden', 'huidig_bewoond', 'woongelegenheden', 'stat_sector', 'hurende_huishoudens',
                 'inwonend_eigenaarsgezin', 'eigenaar_huurder', 'v2210_woonfunctie', 'v2210_bouwjaar_cat', 'v2210_laatste_wijziging_cat',
                 'v2210_woningtype_bouwvorm', 'KI', 'inkomen']].reset_index(drop=True)
del df

# Deaggregatie nodig vooraleer te aggregeren: eigenaar/huurder gaat over een eigendom, maar we willen uitspraken doen over woongelegenheden

# We hebben al een teller met huurders en eigenaars, maar we hebben ook de 'niet bewoonde' nodig om tot de woongelegenheden te komen
# Eens we die drie teleenheden hebben, dan kunnen we ze 'onder elkaar' plakken in een nieuw bestand
# Om te kunnen rekenen, moeten de missings eerst weggewerkt worden
subset[['hurende_huishoudens', 'huidig_bewoond', 'inwonend_eigenaarsgezin']] = subset[['hurende_huishoudens', 'huidig_bewoond', 'inwonend_eigenaarsgezin']].fillna(0)

# We zonderen eerst de niet-bewoonde af
subset['tussenvar_nietbewoond'] = subset['woongelegenheden'] - (subset['hurende_huishoudens'] + subset['inwonend_eigenaarsgezin'])

# Vervolgens maken we een bestand waarin we respectievelijk enkel de onbewoonde, de huurders en de eigenaars in onze uiteindelijke teleenheid steken
deaggregatie = subset[subset['tussenvar_nietbewoond'] > 0] # Ook NaN wordt meegenomen (reflecteren of dit al dan niet de goede keuze is)

# In dit bestand tellen we enkel de ONBEWOONDE
deaggregatie = deaggregatie.rename(columns = {'tussenvar_nietbewoond': 'kubus2210_woongelegenheden'})
# Voor de onbewoonde is er uiteraard geen huurder of eigenaar
deaggregatie['v2210_eigenaar_huurder'] = 0

# Dan de HUURDERS
temp1 = subset[subset['hurende_huishoudens'] > 0].reset_index(drop=True)
temp1.rename(columns={'hurende_huishoudens': 'kubus2210_woongelegenheden'}, inplace = True)
temp1['v2210_eigenaar_huurder'] = 2

# Dan de EIGENAARS
temp2 = subset[subset['inwonend_eigenaarsgezin'] > 0].reset_index(drop=True)
temp2.rename(columns={'inwonend_eigenaarsgezin': 'kubus2210_woongelegenheden'}, inplace = True)
temp2['v2210_eigenaar_huurder'] = 1 # Dus: 0 = onbewoond, 1 = huurders / hurende huishoudens, 2 = eigenaars inwonend

# Breng bovenstaande dataframes samen
deaggregatie = pd.concat([deaggregatie, temp1, temp2])
deaggregatie.reset_index(drop=True, inplace=True)
del subset, temp1, temp2

# Einde deaggregatie

# Aanmaken van variabele om de deaggregatie duidelijk aan te tonen
deaggregatie = deaggregatie.sort_values('eigendom_id').reset_index(drop=True)
deaggregatie = deaggregatie.assign(deaggregatieteller = deaggregatie['eigendom_id'].map(deaggregatie['eigendom_id'].value_counts()))

# =============================================================================
#                           KUBUS WOONGELEGENHEDEN
# =============================================================================

# Verwerking op statsec
deaggregatie['geolevel'] = 'statsec'
deaggregatie.rename(columns = {'stat_sector': 'geoitem', 'jaartal' : 'period'}, inplace = True)
kubus1 = deaggregatie.groupby(['period', 'geolevel', 'geoitem', 'v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
                               'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm'])['kubus2210_woongelegenheden'].sum(min_count = 1).reset_index()
# We voegen ook een verwerking op gemeenteniveau toe - strikt gezien niet nodig, maar helpt Swing vlotter werken
gemeente = kubus1.copy()
gemeente['geoitem'] = gemeente['geoitem'].str[:5]
# Update gewenste niscodes en statistische sectoren
niscodes_to_recode = pd.read_excel('kadaster_parameters.xlsx', sheet_name='niscode', dtype = 'string')
niscodes_replace_dict = dict(zip(niscodes_to_recode['niscode'], niscodes_to_recode['niscode_nieuw']))
gemeente['geoitem'] = gemeente['geoitem'].replace(niscodes_replace_dict)
gemeente['geolevel'] = 'gemeente'
kubus2 = gemeente.groupby(['period', 'geolevel', 'geoitem', 'v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
                           'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm'])['kubus2210_woongelegenheden'].sum(min_count = 1).reset_index()

kubus1 = pd.concat([kubus1, kubus2])
kubus1.dtypes

# Verander het data type (waar het om categorieën gaat) i.f.v. de upload naar PinC. N.B. indien float, dan maakt hij van de decimale sep een underscore
kubus1[['v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
        'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm']] = kubus1[['v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
                                                                               'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm']].astype('Int64')

del gemeente, kubus2

# Exporteer naar een Excelbestand
#kubus1.to_excel('upload/' + jaartal + '/kubus_woongelegenheden_' + jaartal + '.xlsx', sheet_name = 'kubus_woongelegenheden_' + jaartal, index = False) # te groot
kubus1.to_csv('upload/' + jaartal + '/kubus_woongelegenheden_' + jaartal + '.csv', decimal = ',', sep = ';', index = False)
del kubus1

# =============================================================================
#                       KUBUS KADASTRAAL INKOMEN
# =============================================================================

deaggregatie['v2210_ki_bebouwd'] = deaggregatie['inkomen'].str[0:1]
deaggregatie['v2210_ki_belast'] = deaggregatie['inkomen'].str[1:2]
deaggregatie['kubus2210_ki'] = (deaggregatie['KI']/deaggregatie['woongelegenheden']) * deaggregatie['kubus2210_woongelegenheden']

# 'Gewoon gebouwd onroerend goed', i.t.t. ongebouwd, nijverheid, en materieel
deaggregatie[['v2210_ki_bebouwd', 'v2210_ki_belast']] = deaggregatie[['v2210_ki_bebouwd', 'v2210_ki_belast']].fillna('')
deaggregatie['v2210_ki_bebouwd'] = deaggregatie['v2210_ki_bebouwd'].map(lambda x: '1' if x == '2' else '0')
deaggregatie['v2210_ki_belast'] = deaggregatie['v2210_ki_belast'].map(lambda x: '1' if x == 'F' else '0')

# Verwerking op statsec
kubus1 = deaggregatie.groupby(['period', 'geolevel', 'geoitem', 'v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
                               'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm', 'v2210_ki_bebouwd',
                               'v2210_ki_belast'])['kubus2210_ki'].sum(min_count = 1).reset_index()

# We voegen ook een verwerking op gemeenteniveau toe - strikt gezien niet nodig, maar helpt Swing vlotter werken
gemeente = kubus1.copy()
gemeente['geoitem'] = gemeente['geoitem'].str[:5]
# Update gewenste niscodes en statistische sectoren
gemeente['geoitem'] = gemeente['geoitem'].replace(niscodes_replace_dict)
gemeente['geolevel'] = 'gemeente'
kubus2 = gemeente.groupby(['period', 'geolevel', 'geoitem', 'v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
                           'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm', 'v2210_ki_bebouwd',
                           'v2210_ki_belast'])['kubus2210_ki'].sum(min_count = 1).reset_index()

kubus1 = pd.concat([kubus1, kubus2])

# Verander het data type (waar het om categorieën gaat) i.f.v. de upload naar PinC. N.B. indien float, dan maakt hij van de decimale sep een underscore
kubus1[['v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat','v2210_laatste_wijziging_cat',
        'v2210_woningtype_bouwvorm', 'v2210_ki_bebouwd','v2210_ki_belast']] = kubus1[['v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat','v2210_laatste_wijziging_cat',
                                                                                      'v2210_woningtype_bouwvorm', 'v2210_ki_bebouwd','v2210_ki_belast']].astype('Int64')

del gemeente, kubus2

# Exporteer naar een Excelbestand
#kubus1.to_excel('upload/' + jaartal + '/kubus_ki_' + jaartal + '.xlsx', sheet_name = 'kubus_ki_' + jaartal, index = False) # te groot
kubus1.to_csv('upload/' + jaartal + '/kubus_ki_' + jaartal + '.csv', decimal = ',', sep = ';', index = False)
del kubus1

# KI van enkel de gewone bebouwde percelen
deaggregatie = deaggregatie[(deaggregatie['v2210_ki_bebouwd'] == '1') & (deaggregatie['v2210_ki_belast'] == '1')] 

# Verwerking op statsec
kubus1 = deaggregatie.groupby(['period', 'geolevel', 'geoitem', 'v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
                               'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm'])['kubus2210_ki'].sum(min_count = 1).reset_index()
kubus1.rename(columns = {'kubus2210_ki': 'kubus2210_ki_bebouwdbelast'}, inplace = True)

# We voegen ook een verwerking op gemeenteniveau toe - strikt gezien niet nodig, maar helpt Swing vlotter werken
gemeente = kubus1.copy()
gemeente['geoitem'] = gemeente['geoitem'].str[:5]
# Update gewenste niscodes en statistische sectoren
gemeente['geoitem'] = gemeente['geoitem'].replace(niscodes_replace_dict)
gemeente['geolevel'] = 'gemeente'
kubus2 = gemeente.groupby(['period', 'geolevel', 'geoitem', 'v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
                           'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm'])['kubus2210_ki_bebouwdbelast'].sum(min_count = 1).reset_index()

kubus1 = pd.concat([kubus1, kubus2])

# Verander het data type (waar het om categorieën gaat) i.f.v. de upload naar PinC. N.B. indien float, dan maakt hij van de decimale sep een underscore
kubus1[['v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
        'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm']] = kubus1[['v2210_woonfunctie', 'v2210_eigenaar_huurder', 'v2210_bouwjaar_cat',
                                                                               'v2210_laatste_wijziging_cat', 'v2210_woningtype_bouwvorm']].astype('Int64')

del gemeente, kubus2

# Exporteer naar een Excelbestand
#kubus1.to_excel('upload/' + jaartal + '/kubus_ki_bebouwdbelast_' + jaartal + '.xlsx', sheet_name = 'kubus_ki_bebouwdbelast_' + jaartal, index = False)
kubus1.to_csv('upload/' + jaartal + '/kubus_ki_bebouwdbelast_' + jaartal + '.csv', decimal = ',', sep = ';', index = False)

