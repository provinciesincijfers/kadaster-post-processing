# -*- coding: utf-8 -*-
"""
Created on Mon Oct 16 11:37:03 2023

"""
# =============================================================================
#                              CONFIGURATIE
# =============================================================================

# Encoding = windows-1252, in ANSI Latin 1
# Importeer de nodige modules en declareer de main directory
import pandas as pd
import re
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

jaartal = '2022'
ondergrens_bouwjaar = 1931
bovengrens_cat_bouwjaar = 5
ondergrens_wijzigingsjaar = 1983
bovengrens_aantal_kamers = 31
ondergrens_aantal_kamers = 0.9999
bovengrens_aantal_verdiepen = 37
bovengrens_woonoppervlakte = 2000
ondergrens_woonoppervlakte = 10

# =============================================================================
#                       INLEZEN VAN INPUT FILE
# =============================================================================

# Inlezen van de eigendommen
df = pd.read_feather('werkbestanden_python/eigendom_' + jaartal + '.feather')
df['wooneenheden'] = np.where(df['wooneenheden'] >= 999, np.nan, df['wooneenheden']) # Update 21/11/2023.

# Geef aan vanaf welk punt je zaken zelf hebt gedaan
df['AFGELEIDE_VARIABELEN'] = np.nan

# =============================================================================
#           LUIK 1: KOPPELING AAN STATISTISCHE SECTOREN
# =============================================================================
df['LUIK1'] = np.nan

# Inlezen van de meest recente koppeling
koppeling = pd.read_feather('werkbestanden_python\koppeling_meest_recent.feather')

# We maken een nieuw dataframe 'statsec' met de unieke combinaties van de capakeys en de statistische sectoren. Dit zullen we gebruiken om de statsec aan de eigendommen toe te voegen.
statsec = koppeling.groupby(['capakey', 'stat_sector']).size().reset_index(name = 'n_break') # Controleer of dit overal 1 is, bv. door statsec['n_break'].unique() op te vragen
del statsec['n_break'], koppeling # We verwijderen de datasets die we niet meer nodig hebben om memory leaks tegen te gaan

# We hangen de statistische sectoren aan de eigendommen.
df = df.sort_values(by=['capakey'], ignore_index=True)
df = pd.merge(df, statsec, on='capakey', how='left') # voor 982 cases/rows (data 2023) werd er geen statistische sector gevonden (bv. door een foutieve geometrie)
del statsec
#len(df.loc[pd.isna(df['stat_sector'])])

# Van de percelen waaraan we geen statistische sector konden koppelen, weten we wel in welke gemeente ze liggen. Immers is er een 1-op-1-relatie tussen de eerste 5 tekens van de capakey en de gemeente.
df['capa5'] = df['capakey'].str[:5]
df = df.sort_values(by=['capa5'], ignore_index=True) # Vermoedelijk overbodig
tussentabel = pd.read_feather('werkbestanden_python\capa5_niscode.feather') # Deze koppeltabel werd in een eerder script aangemaakt.
tussentabel['capa5'] = tussentabel['capa5'].astype('string')
df = pd.merge(df, tussentabel, on='capa5', how='left')
del tussentabel
df['stat_sector'] = np.where(pd.isna(df['stat_sector']), df['niscode']+'ZZZZ', df['stat_sector'])

# =============================================================================
#                   LUIK 2: VOORBEREIDING INDICATOREN
# =============================================================================
df['LUIK2'] = np.nan

df = df.sort_values(by=['capakey']).reset_index(drop=True) # Als we niet sorteren op capa5, is dit vermoedelijk ook overbodig. 

# Maak een dummy 'BEWOOND' op basis van huidig_bewoond (0 = 'geen huidige bewoning', 1 = 'wel huidige bewoning')
df['bewoond'] = np.where(df['huidig_bewoond'] >= 1, 1, 0)

# AARD
# Recode aard op basis van het Excel-bestand waarin alle parameters gecentraliseerd zijn
overzicht_bewoonbare_aarden = pd.read_excel('kadaster_parameters.xlsx', sheet_name='woonfunctie')
aard_met_woonfunctie = np.array(overzicht_bewoonbare_aarden['aard'])
df['woonfunctie'] = df['aard'].map(lambda x: 1 if not pd.isna(x) and x in aard_met_woonfunctie else 0) # Als de waarde ontbreekt, is er per definitie geen woonfunctie (in lijn met SPSS script)

# WOONGELEGENHEDEN
# Indien woonfunctie = 1 neem dan het grootste van de huishoudens en wooneenheden; indien woonfunctie 0 tel dan het aantal huishoudens
df = df.rename(columns={'woongelegenheden': 'woongelegenheden_cevi'}) # Geef aan dat dit de oorspronkelijke CEVI kolom is
df['woongelegenheden'] = np.where(df['woonfunctie']==1, df[['wooneenheden', 'huidig_bewoond']].max(axis=1), df['huidig_bewoond'])

# WOONAANBOD
# = woongelegenheden waarbij woonfunctie = 1
df['wgl_woonfunctie'] = np.where(df['woonfunctie']==1, df['woongelegenheden'], np.nan)

# TYPE WOONGELEGENHEDEN
# 1 = individuele woning, 2 = appartement, 3 = collectieve woning
df['type_woonaanbod'] = np.where(df['woonfunctie'] == 1, df['aard'].map(overzicht_bewoonbare_aarden.set_index('aard')['type_woonaanbod']), np.nan)

# MEERGEZINSPERCELEN 
# = de minst slechte manier om meergezinswoningen te benaderen.

# Indeling van de woonvoorraad (oftewel alle woongelegenheden)
# We kennen de nodige tussentijdse info toe aan alle perceeldelen (opgelet, deze mag je niet nog eens optellen)
df['woongelegenheden_perceel_tot'] = df.groupby('capakey')['woongelegenheden'].transform('sum', min_count=1)
df = df.assign(aantal_eigendommen = df['capakey'].map(df['capakey'].value_counts()))
# Onderstaande variabele is enkel zinvol op niveau van een perceel, en dat in een dataset op niveau eigendommen. Let dus op bij de interpretatie.
# 1 = 'eigendom op perceel met 1 woongelegenheid, 2 = 'eigendom op perceel met meerdere woongelegenheden'. 
df['eengezin_meergezin'] = np.where(df['woongelegenheden_perceel_tot']==1, 1, np.where(df['woongelegenheden_perceel_tot'] > 1, 2, np.nan))

# HUURDER / EIGENAAR 
# Telling van de huishoudens die we hebben kunnen koppelen
# Classificering van eigendommen naar eigenaars volgens type (E = eigenaar, G = vruchtgebruiker, A = ander recht, H = huurder)
# Recode naar 0 = 'onbekend', 1 = 'eigenaar in brede zin', 2 = 'huurder' en 3 = 'onbewoond
df['eigenaar_huurder'] = df['bewoner_code'].map({'A':1, 'E':1, 'G':1, 'H':2, None:0})
df['eigenaar_huurder'] = np.where(df['huidig_bewoond']==0, 3, df['eigenaar_huurder'])
# Bereken de huishoudens in verhuurde eenheden
# Dit omvat alle huishoudens in verhuurde eigendommen, maar ook extra huishoudens in eigendommen met inwonende eigenaars
df['hurende_huishoudens'] = np.where(df['eigenaar_huurder'] == 2, df['huidig_bewoond'],
                                     np.where((df['eigenaar_huurder']==1) & (df['huidig_bewoond'] > 1), df['huidig_bewoond']-1, np.nan))
# Huishoudens eigenaarswoningen (de fout is kleiner als er slechts één inwonend gezin is op een eigendom)
df['inwonend_eigenaarsgezin'] = np.where(df['eigenaar_huurder']==1, 1, np.nan)

# BOUWJAAR

df[['bouwjaar_clean', 'laatste_wijziging_clean']] = df[['bouwjaar', 'laatste_wijziging']]
# Gebouwen die in de toekomst (of in het huidige jaar) werden gebouwd beschouwen we als 'bouwjaar onbekend'
df['bouwjaar_clean'] = np.where(df['bouwjaar'] >= df['jaartal'], np.nan, df['bouwjaar_clean'])
# Gebouwen die werden gerenoveerd in de toekomst (of in het huidige jaar) beschouwen we als 'wijziging onbekend'
df['laatste_wijziging_clean'] = np.where(df['laatste_wijziging'] >= df['jaartal'], np.nan, df['laatste_wijziging_clean'])
# Gebouwen die pas werden gebouwd nadat ze werden gerenoveerd, beschouwen we als een fout wijzigingsjaar
df['laatste_wijziging_clean'] = np.where((df['laatste_wijziging'] < df['bouwjaar']) & (df['bouwjaar'] >= 0) & (df['laatste_wijziging'] > 0),
                                         np.nan, df['laatste_wijziging_clean'])
# Als het bouwjaar groter is dan 5 en kleiner dan 1931, dan is het fout
df['bouwjaar_clean'] = np.where((df['bouwjaar'] > bovengrens_cat_bouwjaar) & (df['bouwjaar'] < ondergrens_bouwjaar), np.nan, df['bouwjaar_clean'])
# Als het wijzigingsjaar kleiner is dan 1983, dan is het wellicht een raar geval en nemen we het niet mee
df['laatste_wijziging_clean'] = np.where((df['laatste_wijziging'] > 0) & (df['laatste_wijziging'] < ondergrens_wijzigingsjaar), np.nan, df['laatste_wijziging_clean'])

# Recode bouwjaar_clean naar de gewenste categorie (cfr. Excel kadaster_parameters)
overzicht_bouwjaar_cat = pd.read_excel('kadaster_parameters.xlsx', sheet_name='bouwjaar')
bouwjaar_cat_dict = overzicht_bouwjaar_cat.set_index(['bouwjaar_ondergrens', 'bouwjaar_bovengrens']).to_dict()['bouwjaar_cat']
def map_categorie_aan_bouwjaar(jaar):
    for grenzen, categorie in bouwjaar_cat_dict.items():
        ondergrens, bovengrens = grenzen
        if ondergrens <= jaar <= bovengrens:
            return categorie
    return 13 # Let dus op: in 2031 komt er een extra categorie/range bij en krijgt de categorie 'onbekend' het label 14.
df['bouwjaar_cat'] = df['bouwjaar_clean'].apply(map_categorie_aan_bouwjaar)
# Extrapoleer naar de woongelegenheden
df['bouwjaar_cat_wgl'] = np.where(df['woongelegenheden'] >= 1, df['bouwjaar_cat'], np.nan)

# Recode laatste_wijziging_clean naar de gewenste categorieën
overzicht_laatste_wijziging_cat = pd.read_excel('kadaster_parameters.xlsx', sheet_name='laatste_wijziging')
laatste_wijziging_cat_dict = overzicht_laatste_wijziging_cat.set_index(['laatste_wijziging_ondergrens', 'laatste_wijziging_bovengrens']).to_dict()['laatste_wijziging_cat']
def map_categorie_aan_laatste_wijziging(jaar):
    for grenzen, categorie in laatste_wijziging_cat_dict.items():
        ondergrens, bovengrens = grenzen
        if ondergrens <= jaar <= bovengrens:
            return categorie
    return 13 # Let dus op: in 2031 komt er een extra categorie/range bij en krijgt de categorie 'onbekend' het label 14.
df['laatste_wijziging_cat'] = df['laatste_wijziging_clean'].apply(map_categorie_aan_laatste_wijziging)
# Extrapoleer naar de woongelegenheden
df['laatste_wijziging_cat_wgl'] = np.where(df['woongelegenheden'] >= 1, df['laatste_wijziging_cat'], np.nan)

# We maken een combinatie van bouwjaar en wijzigingsjaar om een indicatie te krijgen van de 'recentheid' van het woonpatrimonium
df['recentste_jaar'] = df[['bouwjaar_clean', 'laatste_wijziging_clean']].max(axis=1)

# BOUWVORM 
# zie afspraken 2020-10-16
df['soort_bebouwing'].fillna('', inplace=True)
df['egw_open_bouwvorm'] = np.where((df['eengezin_meergezin'] == 1) & (df['soort_bebouwing']=='Open bebouwing'), 
                                   df['woongelegenheden'], np.nan)
df['egw_halfopen_bouwvorm'] = np.where((df['eengezin_meergezin'] == 1) & (df['soort_bebouwing']=='Halfopen bebouwing'), 
                                   df['woongelegenheden'], np.nan)
df['egw_gesloten_bouwvorm'] = np.where((df['eengezin_meergezin'] == 1) & (df['soort_bebouwing']=='Gesloten bebouwing'), 
                                   df['woongelegenheden'], np.nan)
df['egw_andere_bouwvorm'] = np.where((df['eengezin_meergezin'] == 1) & (~df['soort_bebouwing'].isin(['Open bebouwing', 'Halfopen bebouwing', 'Gesloten bebouwing'])), 
                                   df['woongelegenheden'], np.nan)

del overzicht_bewoonbare_aarden, overzicht_bouwjaar_cat, overzicht_laatste_wijziging_cat

# =============================================================================
#                   LUIK 3: TOEVOEGEN BEWONING ZONDER LINK
# =============================================================================
df['LUIK3'] = np.nan

# Inlezen bewoning zonder link
na_values = ['NaN', '', 'NULL', 'null']
bzl = pd.read_csv(jaartal + '\KAD_'+ jaartal + '_bewoning_zonder_link.txt', delimiter = '\t',
                  dtype={'provincie': 'string', 'jaartal':'int32', 'niscode': 'string', 'adrescode': 'string', 'straatnaamdcode':'int32',
                         'huisbis':'string', 'aantal_gezinnen':'int32'},
                  keep_default_na = False, na_values = na_values)

# Update gewenste niscodes en statistische sectoren
niscodes_to_recode = pd.read_excel('kadaster_parameters.xlsx', sheet_name='niscode', dtype = 'string')
niscodes_replace_dict = dict(zip(niscodes_to_recode['niscode'], niscodes_to_recode['niscode_nieuw']))
bzl['niscode'] = bzl['niscode'].replace(niscodes_replace_dict)
bzl['stat_sector'] = bzl['niscode']+'ZZZZ'
bzl.rename(columns={'aantal_gezinnen':'bewoning_zonder_link'}, inplace=True)
bzl.drop(columns=['adrescode', 'straatnaamcode', 'huisbis'], inplace=True)

# Aggregeer de bzl dataframe en sommeer hierbij de bewoning zonder link
aggr = bzl.groupby(['provincie', 'jaartal', 'niscode', 'stat_sector'])['bewoning_zonder_link'].sum().reset_index()

# Hang het eindresultaat van de bzl operatie onder de eigendommen dataframe
df = pd.concat([df, aggr], ignore_index=True)
del bzl, aggr

# =============================================================================
#                   LUIK 4: TOEVOEGEN PARCEL DATA
# =============================================================================
df['LUIK4'] = np.nan

# Inladen parcel dataset
parcel = pd.read_feather('werkbestanden_python/parcel_' + jaartal + '.feather')
parcel['nature'] = parcel['nature'].astype(int)
parcel = parcel.sort_values(by=['nature']).reset_index(drop=True)
#test = parcel.head(1000)

# Inladen koppeltabel nature / nis-indeling
nature = pd.read_csv('koppeltabellen/nature_nisindeling.csv', sep=';', dtype={'Nature':'int32', 'nis_indeling':'string'})
nature.rename(columns={'Nature':'nature'}, inplace=True)
nature = nature.sort_values(by=['nature']).reset_index(drop=True)

# Hang de nisindeling aan de parcel dataset op basis van de gemeenschappelijke nature kolom
parcel = parcel.merge(nature, on=['nature'], how = 'left')
del nature

# In dit bestand zijn er dubbels, maar in de onderwerpen die we nodig hebben, lijken de waarden steeds identiek
#sum(parcel['eigendom_id'].duplicated()) #1.1% in 2023
agg_functies = {
    'builtSurface': 'first',
    'usedSurface': 'first',
    'placeNumber': 'first',
    'floorNumberAboveground': 'first',
    'descriptPrivate': 'first',
    'garret': 'first',
    'floor': 'first',
    'nature': 'first',
    'surfaceNotTaxable': 'sum',
    'surfaceTaxable': 'sum',
    'nis_indeling': 'first'}
parcelagg = parcel.groupby('eigendom_id').agg(agg_functies).reset_index()
del parcel # Werkgeheugen vrijmaken

# Sorteer de eigendommen en hang de geaggregeerde parcel dataset eraan
df = df.sort_values(by='eigendom_id', na_position='first')
df = df.reset_index(drop=True)
df = df.merge(parcelagg, on=['eigendom_id'], how = 'left')
del parcelagg # Werkgeheugen vrijmaken

# OPPERVLAKTES LANDGEBRUIK
df[['surfaceNotTaxable', 'surfaceTaxable']] = df[['surfaceNotTaxable', 'surfaceTaxable']].fillna(0)
df['surface_total'] = df['surfaceNotTaxable'] + df['surfaceTaxable']

# AANTAL KAMERS IN WONINGEN

# Woonplaatsen of kamers. Ook ingevuld voor andere zaken dan wooneenheden.
df['v2210_aantal_kamers'] = np.where(df['woonfunctie']==1, df['placeNumber'], np.nan)
df['kamers_per_woning'] = df['v2210_aantal_kamers']/df['woongelegenheden']
df['kamers_per_woning'] = df['kamers_per_woning'].replace([np.inf, -np.inf], np.nan) # Corrigeer oneindige waardes (gegenereerd door /0) naar missing

# Verander extreme waardes naar missing (N.B. uitzondering bovengrens voor kastelen)
df['subtype_woning'].fillna('', inplace=True)
df['kamers_per_woning'] = np.where((df['subtype_woning'] == 'Kasteel') & (df['kamers_per_woning'] <= ondergrens_aantal_kamers), np.nan,
                                   np.where((df['subtype_woning'] != 'Kasteel') & ((df['kamers_per_woning'] <= ondergrens_aantal_kamers) | (df['kamers_per_woning'] >= bovengrens_aantal_kamers)),
                                            np.nan, df['kamers_per_woning']))
# Indien het een extreme waarde betreft, verwijder dan ook de teller zelf
df['v2210_aantal_kamers'] = np.where(pd.isna(df['kamers_per_woning']), np.nan, df['v2210_aantal_kamers'])

# Maak bijkomende tellers
df['v2210_wgl_met_kamers'] = np.where(df['v2210_aantal_kamers'] > 0, df['woongelegenheden'], np.nan)
df['v2210_woning_met_kamers'] = np.where(df['v2210_aantal_kamers'] > 0, df['wooneenheden'], np.nan)

# VERDIEPINGEN, VERDIEP EN AARD

# floorNumberAboveground, garret EN descriptPrivate
# floorNumberAboveground bevat het aantal bouwlagen voor zaken met verdiepingen, bv. een huis of een appartementsblok
# floor bevat de verdieping zelf van de eigendom, bv. een appartement op de derde verdieping
# descriptPrivate gaat over waar op het perceel een perceeldeel ligt. Dit bevat indien nodig de verdieping van de entiteit in kwestie, bv. een appartement. 
# garret gaat over bewoonde zolders.

# Er zijn heel wat panden met 0 verdiepen (i.e. 1 bouwlaag), maar slechts zelden is dit bij een type gebouw waar je dat niet zou verwachten.
# We maken een variabele die op gebouwniveau van toepassing is (n_verdiep) en een die op wooneenheden van toepassing is (verdiep)
# Aangezien gebouwen geen eenheid zijn in het kadaster, moeten we helaas aggregeren op perceel. We nemen dan de hoogste van de twee variabelen en tellen er eventueel nog de bewoonde zolders bij.

# Hetzelfde perceel kan huizen en appartementen hebben, met elk een eigen aantal verdiepingen. 
# Doorgaans heeft een perceel met appartementen een enkele record met het aantal verdiepingen, de rest staat op missing.

# Enkel van 'buildings' (een enkele eigenaar) worden verdiepen geregistreerd in de constructiecode, niet van woningen in een building.
# Daarom is het nodig om ook het veld "descriptPrivate' (gedetailleerde ligging of iets dergelijks) te gebruiken. 

df['n_verdiep'] = df['floorNumberAboveground']-1

# descriptPrivate bevat mogelijk zowel 'aard' als het verdiep. In theorie kan de aard enkel onderstaande zijn.
df['descript_clean'] = df['descriptPrivate'].str.replace(r'^[ .#/"]+', '', regex=True) # Verwijder voorlooptekens 
# In SPSS zijn er nog spaties aanwezig, wat vermoedelijk resulteert in fouten binnen aard_descript.
overzicht_aard_descript = pd.read_excel('kadaster_parameters.xlsx', sheet_name='aard')
aard_descript = tuple(overzicht_aard_descript['aard_descript'])

# Als het descript strart met een aard aanwezig in het Excelbestand, extraheer dan die aard. 
# Let op: de configuratie van de functie zorgt ervoor dat de volgorde van de aard in het Excelbestand van groot belang is (bv. KA krijgt voorrang op K)
df['descript_clean'].fillna('', inplace=True)
def extract_matching_string(value, strings):
    for s in strings:
        if value.startswith(s):
            return s
    return ''
df['aard_descript'] = np.where(df['descript_clean'].str.startswith(aard_descript),
                               df['descript_clean'].apply(extract_matching_string, strings = aard_descript), '')

# In theorie volgt onmiddellijk op aard de verdieping
df['verdiep0'] = df.apply(lambda x: x['descript_clean'].replace(x['aard_descript'], '', 1) if x['aard_descript'] and x['descript_clean'].startswith(x['aard_descript']) else '', axis=1)

# Normaal gezien volgt op het verdiep een slash of niets meer
df['verdiep1'] = df['verdiep0'].apply(lambda x: x.split('/')[0] if '/' in x else x)

# We verwijderen spaties en punten
df['verdiep1'] = df['verdiep1'].str.replace(r'^[ .]+', '', regex=True)

# Soms staan er nog speciale karakters voor het verdiep (.-@&+)
# In beide gevallen gaan we ervan uit dat het verdiep dan omschreven staat vóór het speciale karakter.
# Opmerking: soms staat er iets als 1.2.3; dit wijzen we toe als 1 in lijn met het SPSS script.
df['verdiep1'] = df['verdiep1'].apply(lambda x: re.split(r'[.\- @&+]', x)[0] if re.search(r'[.\- @&+]', x) else x)

# We gaan ervan uit dat als het verdiepnummer nu nog altijd begint met OG, GV, TV of BE, alles wat erachter komt weg mag. N.B. neem BE niet mee om incorrecte toewijzingen te voorkomen.
df['verdiep1'] = df['verdiep1'].apply(lambda x: x[:2] if x.startswith(('GV', 'OG', 'TV')) else x)

# We zetten dit om naar een numerieke waarde (N.B. in lijn met SPSS, nemen we enkel de eerste drie nummers. Bv. "70701" wordt 707). Dit zal nog geherevalueerd worden.
# Verander komma's naar punten om een transformatie naar numerieke waarden te optimaliseren
mapping = {'GV': 0, 'OG': -1, 'TV': 0.5, 'BE': 0.75}
df['verdiep'] = np.where(df['verdiep1'].isin(mapping.keys()), df['verdiep1'].map(mapping), pd.to_numeric(df['verdiep1'].str[:3].str.replace(',','.'), errors='coerce')) # Enkel de eerste 3 chars nemen, lijkt niet optimaal (introduceren fouten)

# Indien S, G, K, P of B, dan is het een nummer en geen verdiep
# Indien VITR dan is het nog iets anders
df['verdiep'] = df.apply(lambda x: np.nan if x['aard_descript'] in ["S", "G", "K", "P", "B", "VITR"] else x['verdiep'], axis=1)

# Enkele records hebben een belachelijk hoog aantal verdiepingen
# Vanaf hoeveel verdiepen het absurd wordt, is natuurlijk gebiedsafhankelijk
# We leggen de grens op 10, omdat er vrij veel ruis is op de data
df['verdiep'] = np.where(df['verdiep'] > 10, np.nan, df['verdiep']) # Verder staat een andere bovengrens gedefinieerd (to do: verbeter consistentie)
#max(df.loc[~pd.isna(df['verdiep'])]['verdiep'])
# Einde toewijzing verdiep per record
# We aggregeren per perceel om het aantal verdiepen van gebouwen te benaderen

# Opkuisen aard
df.rename(columns={'aard_descript': 'aard0'}, inplace = True)
overzicht_cat_aard_descript = pd.read_excel('kadaster_parameters.xlsx', sheet_name='aard')
aard_descript_cat_dict = dict(zip(overzicht_cat_aard_descript['aard_descript'], overzicht_cat_aard_descript['cat']))
df['aard_descript'] = df['aard0'].replace(aard_descript_cat_dict)
df.drop(columns=['verdiep0', 'verdiep1', 'aard0', 'descript_clean'], inplace=True)

# Verrijken met de officiële variabele 'floor'. In het geval deze beschikbaar is, dan is deze juister dan verdiep.
#max(df.loc[~pd.isna(df['floor'])]['floor'])
df['verdiep'] = np.where(df['floor'] >= 0, df['floor'], df['verdiep'])

# Het hoogste gebouw van België heeft 36 verdiepen.
#max(df.loc[~pd.isna(df['verdiep'])]['verdiep'])
df['verdiep'] = df['verdiep'].apply(lambda x: x if x < bovengrens_aantal_verdiepen else None)
df['n_verdiep'] = df['n_verdiep'].apply(lambda x: x if 0 <= x < bovengrens_aantal_verdiepen else None) # Eigendommen met een negatief aantal verdiepen tellen we niet mee.

# We tellen enkel de verdiepen op de bebouwde aarden.
df['n_verdiep'] = np.where(df['nis_indeling'].astype(str).str.startswith('1'), None, df['n_verdiep'])
df['verdiep'] = np.where(df['nis_indeling'].astype(str).str.startswith('1'), None, df['verdiep'])

# We maken een variabele om de 'beste' verdiepschatting te maken per perceel
df[['n_verdiep_max', 'verdiep_max', 'dakverdiep_max']] = df.groupby('capakey')[['n_verdiep', 'verdiep', 'garret']].transform('max')


df['verdiepen_perceel'] = df[['n_verdiep_max', 'verdiep_max']].max(axis=1, skipna=True)
df['verdiepen_perceel'] = df['verdiepen_perceel'].apply(lambda x: int(x) if not pd.isna(x) else x)
df['verdiepen_inc_dakverdiep'] = np.where(df['dakverdiep_max']==1, df['verdiepen_perceel']+1, df['verdiepen_perceel'])
df.drop(columns=['n_verdiep_max', 'verdiep_max', 'dakverdiep_max'], inplace=True)

# Ee negatief aantal verdiepen op een perceel is onmogelijk
df['verdiepen_perceel'] = np.where(df['verdiepen_perceel'] <= 0, 0, df['verdiepen_perceel'])
df['verdiepen_inc_dakverdiep'] = np.where(df['verdiepen_inc_dakverdiep'] <= 0, 0, df['verdiepen_inc_dakverdiep'])


# BEWOONBARE OPPERVLAKTE

# Weerhoud enkel oppervlaktes als ze realistisch zijn
# Bereken de oppervlakte per wooneenheid op wooneigendommen
df['opp_per_wooneenheid'] = np.where((df['woonfunctie']==1) & (df['wooneenheden'] != 0), df['usedSurface']/df['wooneenheden'], np.nan)

# Telt enkel als woonoppervlakte indien woonfunctie én minder dan 2000 m2 en groter dan 10 m2.
df['v2210_woonoppervlakte'] = np.where((df['opp_per_wooneenheid'] >= ondergrens_woonoppervlakte) & (df['opp_per_wooneenheid'] < bovengrens_woonoppervlakte) & (df['woonfunctie'] == 1),
                                       df['usedSurface'], np.nan)
df['opp_per_wooneenheid'] = df['v2210_woonoppervlakte'] / df['wooneenheden']
df['v2210_wooneenheid_opp'] = np.where(df['v2210_woonoppervlakte'] > 0, df['wooneenheden'], np.nan)
df['v2210_wgl_opp'] = np.where(df['v2210_woonoppervlakte'] > 0, df['woongelegenheden'], np.nan)

# =============================================================================
#                                   LABEL VARIABELEN
# =============================================================================
variable_labels = {
    'AFGELEIDE_VARIABELEN': 'D&A afgeleide variabelen',
    'LUIK1': 'LUIK1: localisatie',
    'stat_sector': 'statsec (uit meest recente koppeling.txt + correcties)',
    'capa5': 'capa5 (voor niet te lokaliseren percelen)',
    'niscode': 'niscode (uit meest recente koppeling.txt)',
    'LUIK2': 'LUIK2: basisconcepten',
    'bewoond': 'al of niet bewoond',
    'woonfunctie': 'woonfunctie (op aard)',
    'wgl_woonfunctie': 'woongelegenheden op eigendom met woonfunctie',
    'type_woonaanbod': 'soort woning (op aard)',
    'woongelegenheden_perceel_tot': 'totaal woongelegenheden op dit perceel (niet optelbaar!)',
    'aantal_eigendommen': 'totaal eigendommen op dit perceel (niet optelbaar!)',
    'eengezin_meergezin': 'eengezin (1) of meergezinswoning (2) (volgens aantal wgl. op perceel)',
    'eigenaar_huurder': 'huurder/eigenaar (0 onbekend/1 eigenaar/2 huurder/3 onbewoond)',
    'hurende_huishoudens': 'aantal huurders op eigendom',
    'inwonend_eigenaarsgezin': 'aantal eigenaars op eigendom',
    'bouwjaar_clean': 'bouwjaar (gecleaned)',
    'laatste_wijziging_clean': 'jaar laatste wijziging (gecleaned)',
    'bouwjaar_cat': 'categorie bouwjaren',
    'bouwjaar_cat_wgl': 'categorie bouwjaren (enkel ingevuld voor eig met wgl)', 
    'laatste_wijziging_cat': 'categorie wijzigingsjaren',
    'laatste_wijziging_cat_wgl': 'categorie wijzigings (enkel ingevuld voor eig met wgl)',
    'recentste_jaar': 'recentste van bouwjaar en wijzigingsjaar',
    'egw_open_bouwvorm': 'egw in open bebouwing',
    'egw_halfopen_bouwvorm': 'egw in halfopen bebouwing',
    'egw_gesloten_bouwvorm': 'egw in gesloten bebouwing',
    'egw_andere_bouwvorm': 'egw anders/onbekend',
    'LUIK3': 'LUIK3: bewoning zonder link',
    'bewoning_zonder_link': 'huishoudens die niet gekoppeld konden worden aan kadaster (per statsec)',
    'LUIK4': 'LUIK4: data uit parcel',
    'builtSurface': 'builtSurface',
    'usedSurface': 'usedSurface',
    'placeNumber': 'placeNumber',
    'floorNumberAboveground': 'floorNumberAboveground',
    'descriptPrivate': 'descriptPrivate',
    'garret': 'garret',
    'floor': 'floor',
    'nature': 'nature',
    'surfaceNotTaxable': 'surfaceNotTaxable',
    'surfaceTaxable': 'surfaceTaxable',
    'surface_total': 'surface (som Not/taxable)',
    'nis_indeling': 'nis indeling (statbel bodembezetting) van nature',
    'v2210_aantal_kamers': 'kamers (enkel indien woonfunctie)',
    'kamers_per_woning': 'kamers per wgl',
    'v2210_wgl_met_kamers': 'aantal wgl met bekend aantal kamers',
    'v2210_woning_met_kamers': 'aantal woningen met bekend aantal kamers',
    'n_verdiep': 'aantal verdiepen van het eigendom',
    'verdiep': 'verdiep waarop het eigendom ligt',
    'aard_descript': 'type goed volgens descriptprivate',
    'verdiepen_perceel': 'aantal verdiepen van het perceel',
    'verdiepen_inc_dakverdiep': 'aantal verdiepen van het perceel (dakverdieping meegerekend)',
    'opp_per_wooneenheid': 'nuttige oppervlakte per wooneenheid',
    'v2210_woonoppervlakte': 'nuttige oppervlakte van wooneenheden',
    'v2210_wooneenheid_opp': 'wooneenheden met gekende nuttige oppervlakte',
    'v2210_wgl_opp': 'wgl met gekende nuttige oppervlakte'}

# =============================================================================
#                                EXPORT
# =============================================================================

df['aard_descript'] = df['aard_descript'].replace('', np.nan) # Een feather bestand vereist duidelijke datatypes (geen object type)
df.to_feather('werkbestanden_python/eigendom_' + jaartal + '_basisafspraken.feather') # Dit formaat draagt de voorkeur voor Python verwerkingen
#df.to_csv('werkbestanden_python/eigendom_' + jaartal + '_basisafspraken.csv') # Neemt wat tijd in beslag en vereist een dubbele hoeveelheid opslagruimte
#pyreadstat.write_sav(df, 'werkbestanden_python/eigendom_' + jaartal + '_basisafspraken.sav') # Neemt veel tijd in beslag


