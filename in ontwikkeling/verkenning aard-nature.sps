* Encoding: windows-1252.
* map met alle kadasterdata.
DEFINE datamap () 'C:\temp\kadaster\' !ENDDEFINE.
* dit gaat ervan uit dat je een map "upload" hebt in deze map.

* map met alle data die van Github komt.
DEFINE github () 'C:\github\' !ENDDEFINE.

* jaartal waarvoor we werken.
DEFINE datajaar () '2020' !ENDDEFINE.

GET
  FILE=datamap +  'werkbestanden\eigendom_' + datajaar + '_basisafspraken.sav'.
DATASET NAME eigendommen WINDOW=FRONT.

* code overgenomen van https://github.com/StudiedienstAntwerpen/be-cadastre/blob/master/methode_vanaf_2016/n05_basis_percelen_sectoren.sps.

recode aard
('D.AP.GEB.#GW'=220)
('D.AP.GEB.#W'=220)
('OPP & G.D.'=64)
('BOS'=9)
('MAT.& OUT. ONG.'=80)
('SCHAAPSWEI'=8)
('D.PARKING#'=79)
('BOUWGROND'=78)
('KOER'=77)
('BASSIN GEWOON'=76)
('WIJMLAND'=75)
('KERKHOF'=74)
('MILIT.TERREIN'=73)
('VLIEGVELD'=72)
('PARKING'=71)
('GROND'=70)
('VETWEIDE'=7)
('BEB.OPP.NIJVER.'=69)
('BEB.OPP.UITZ.'=68)
('BEB.OPP.GEWOON'=67)
('MERKSTEEN'=63)
('GRAFHEUVEL'=62)
('SCH. HOOILAND'=6)
('KANAAL'=59)
('GROEVE'=57)
('STEENBERG EXP.'=56)
('SPEC.GEM.DELEN ONG'=551)
('CABINE #'=550)
('SPOORWEG'=55)
('DIV.PRIV.DEEL #'=549)
('ETALAGE #'=547)
('RESERVE #'=546)
('NT.OVERD.PARK. #'=545)
('OVERD.PARKING #'=544)
('GARAGEBOX #'=543)
('UITBATINGSEENH. #'=542)
('OPSTAL/ERFPACHT'=541)
('BASSIN NIJV.'=54)
('ANDERE GEBOUWD'=539)
('ALG.GEM.DELEN ONG'=538)
('APPARTEMENT #'=537)
('KANTOOR #'=536)
('HANDELSPAND #'=535)
('STUDIO #'=534)
('KAMER #'=533)
('KELDER #'=532)
('AFVALVERWERKING'=531)
('ZUIVERINGSINST.'=530)
('WATERWINNING'=529)
('WATERTOREN'=528)
('WATERMOLEN'=527)
('WINDMOLEN'=526)
('MONUMENT'=525)
('HISTOR. GEBOUW'=524)
('KASTEEL'=523)
('PAVILJOEN'=522)
('ONDERGR.RUIMTE'=521)
('PUIN'=520)
('KAAI'=52)
('UITKIJK'=510)
('WERF'=51)
('CASINO'=509)
('BIOSCOOP'=508)
('CULTUR.CENTRUM'=507)
('SPEKTAKELZAAL'=506)
('THEATER'=505)
('JEUGDHEEM'=504)
('VAKANTIE VERBL.'=503)
('VAKAN.TEHUIS'=502)
('SPORTGEBOUW'=501)
('BADINRICHTING'=500)
('NIJV.GROND'=50)
('WARMOESGR.'=5)
('STORT.EXP.'=49)
('GEBOUW ERED.'=489)
('TEMPEL'=488)
('MOSKEE'=487)
('SYNAGOGE'=486)
('BISDOM'=485)
('SEMINARIE'=484)
('PASTORIE'=483)
('KLOOSTER'=482)
('KAPEL'=481)
('KERK'=480)
('BIBLIOTHEEK'=463)
('MUSEUM'=462)
('UNIVERSITEIT'=461)
('SCHOOLGEBOUW'=460)
('STORT.WGR.'=46)
('STEENBERG WGR.'=45)
('WELZIJNSGEBOUW'=446)
('KUURINRICHTING'=445)
('VERPLEEGINR.'=444)
('RUSTHUIS'=443)
('BESCHER.WERKPL.'=442)
('KINDERBEWARING'=441)
('WEESHUIS'=440)
('DIJK'=44)
('ADMIN.GEBOUW'=434)
('LIJKENHUIS'=433)
('LUCHTHAVEN'=432)
('TELECOM.GEBOUW'=431)
('TELEFOONCEL'=430)
('WAL'=43)
('WACHTHUIS'=429)
('STATION'=428)
('MILIT.GEBOUW'=427)
('POLITIEGEBOUW'=426)
('GEZANTSCH.GEB.'=425)
('STRAFINRICHTING'=424)
('GERECHTSHOF'=423)
('KONINKL.PALEIS'=422)
('GOUVER.GEBOUW'=421)
('GEMEENTEHUIS'=420)
('DUIN'=42)
('DIERENGEBOUW'=415)
('KIOSK'=414)
('TOONZAAL'=413)
('OVERDEKTE MARKT'=412)
('SERVICESTATION'=411)
('PARKEERGEBOUW'=410)
('AANSPOELING'=41)
('GARAGESTELPL.'=409)
('GROOTWARENHUIS'=408)
('HANDELSHUIS'=407)
('FEESTZAAL'=406)
('RESTAURANT'=405)
('HOTEL'=404)
('DRANKHUIS'=403)
('KANTOORGEBOUW'=402)
('BEURS'=401)
('BANK'=400)
('TUIN'=4)
('VEEN'=39)
('BEDRIJFSCOMPL#'=382)
('MAT.& OUT. GEB.'=381)
('KOELINRICHTING'=380)
('MOERAS'=38)
('DROOGINSTALL.'=379)
('ONDERZOEKSCENT.'=378)
('SILO'=377)
('RESERVOIR'=376)
('CABINE'=375)
('GASCABINE'=374)
('PYLOON'=373)
('ELEKTR.CABINE'=372)
('MAGAZIJN'=371)
('HANGAR'=370)
('HEIDE'=36)
('NIJV.GEBOUW'=357)
('GAZOMETER'=355)
('GASFABRIEK'=354)
('ELEKTR.CENTRALE'=353)
('KOLENMIJN'=352)
('AARDEW.FABRIEK'=351)
('PLAST.FABRIEK'=350)
('WOESTE GROND'=35)
('GLASFABRIEK'=349)
('IJSFABRIEK'=348)
('RUBBERFABRIEK'=347)
('CHEMISCH.FABRIEK'=346)
('PETROL.RAFF.'=345)
('ELEK.MAT.FAB.'=344)
('CONSTR.WERKPL.'=343)
('KALKOVEN'=342)
('METAALNIJV.'=340)
('PLEIN'=34)
('WEG'=33)
('BOUWMAT.FABRIEK'=324)
('VERFFABRIEK'=323)
('ZAGERIJ'=322)
('CEMENTFABRIEK'=321)
('STEENBAKKERIJ'=320)
('GEBRUIKSART.FAB.'=306)
('PAPIERFABRIEK'=305)
('SPEELG.FABRIEK'=304)
('MEUBELFABRIEK'=303)
('LEDERWAR.FAB.'=302)
('TEXTIELFABRIEK'=301)
('KLEDINGFABRIEK'=300)
('VISKWEKERIJ'=30)
('HOOILAND'=3)
('VOEDINGSFABRIEK'=290)
('SLOOT'=29)
('MAALDERIJ'=289)
('TABAKFABRIEK'=288)
('DRANKFABRIEK'=287)
('BROUWERIJ'=286)
('KOFFIEFABRIEK'=285)
('VEEVOE.FABRIEK'=284)
('SLACHTERIJ'=283)
('VLEESW.FABRIEK'=282)
('BAKKERIJ'=281)
('ZUIVELFABRIEK'=280)
('GRACHT'=28)
('MEER'=27)
('WERKPLAATS'=265)
('WASSERIJ'=264)
('SCHRIJNWERKERIJ'=263)
('SMIDSE'=262)
('GARAGEWERKPL.'=261)
('DRUKKERIJ'=260)
('VIJVER'=26)
('POEL'=25)
('LANDGEBOUW'=247)
('PADDEST.KWEK.'=246)
('SERRE'=245)
('GR.VEETEELT'=244)
('KL.VEETEELT'=243)
('DUIVENTIL'=242)
('PAARDESTAL'=241)
('HOEVE'=240)
('WELWATER'=24)
('HUIS#'=223)
('BUILDING'=222)
('PRIVAT. DELEN'=221)
('ZWEMBAD'=22)
('KAMPEERTERREIN'=21)
('LAVATORY'=206)
('AFDAK'=205)
('GARAGE'=204)
('BERGPLAATS'=203)
('KROTWONING'=202)
('NOODWONING'=201)
('HUIS'=200)
('SPEELTERREIN'=20)
('WEILAND'=2)
('SPORTTERREIN'=18)
('ANDERE ONGEBWD'=170)
('PARK'=17)
('BEB.OPP.APP.'=166)
('SPEC.GEM.DELEN GEB'=165)
('ALG.GEM.DELEN GEB'=164)
('KERSTBOMEN'=14)
('BOOMKWEKERIJ'=13)
('BOOMGAARD LAAG'=11)
('BOOMGAARD HOOG'=10)
('BOUWLAND'=1) into nature.



* indeling Vreidi.
recode nature
(220=1)
(200=1)
(201=1)
(202=1)
(203=1)
(205=1)
(206=1)
(240=1)
(532=1)
(164=1)
(165=1)
(166=1)
(204=8)
(221=1)
(222=1)
(223=1)
(241=7)
(242=7)
(243=7)
(244=7)
(245=7)
(246=7)
(247=7)
(260=2)
(261=2)
(262=2)
(263=2)
(264=2)
(265=2)
(280=2)
(281=2)
(282=2)
(283=2)
(284=2)
(285=2)
(286=2)
(287=2)
(288=2)
(289=2)
(290=2)
(300=2)
(301=2)
(302=2)
(303=2)
(304=2)
(305=2)
(306=2)
(320=2)
(321=2)
(322=2)
(323=2)
(324=2)
(340=2)
(341=2)
(342=2)
(343=2)
(344=2)
(345=2)
(346=2)
(347=2)
(348=2)
(349=2)
(350=2)
(351=2)
(352=2)
(353=2)
(354=2)
(355=2)
(356=2)
(357=2)
(370=2)
(371=2)
(372=4)
(373=4)
(374=4)
(375=4)
(376=2)
(377=2)
(378=4)
(379=2)
(380=2)
(381=2)
(382=2)
(400=2)
(401=2)
(402=2)
(403=2)
(404=2)
(405=2)
(406=5)
(407=3)
(408=2)
(409=8)
(410=8)
(411=2)
(412=2)
(413=2)
(414=2)
(415=2)
(420=4)
(421=4)
(422=4)
(423=4)
(424=4)
(425=4)
(426=4)
(427=4)
(428=4)
(429=4)
(430=4)
(431=4)
(432=4)
(433=4)
(434=4)
(440=4)
(441=4)
(442=4)
(443=4)
(444=4)
(445=4)
(446=4)
(460=4)
(461=4)
(462=5)
(463=5)
(480=4)
(481=4)
(482=4)
(483=4)
(484=4)
(485=4)
(486=4)
(487=4)
(488=4)
(489=4)
(500=5)
(501=5)
(502=5)
(503=5)
(504=5)
(505=5)
(506=5)
(507=5)
(508=5)
(509=5)
(510=9)
(520=9)
(521=9)
(522=9)
(523=4)
(524=4)
(525=4)
(526=4)
(527=4)
(528=4)
(529=4)
(530=4)
(531=4)
(1=7)
(2=7)
(3=7)
(4=7)
(5=7)
(9=6)
(10=7)
(11=7)
(13=7)
(17=6)
(18=5)
(20=5)
(21=5)
(25=8)
(26=8)
(27=8)
(28=8)
(29=8)
(33=8)
(34=8)
(35=6)
(36=6)
(38=6)
(41=6)
(43=6)
(44=6)
(46=6)
(50=2)
(51=2)
(52=2)
(55=2)
(59=8)
(67=9)
(68=9)
(69=2)
(70=9)
(71=8)
(72=4)
(73=4)
(74=6)
(76=8)
(77=9)
(78=1)
(79=8)
(80=9)
(533=1)
(534=1)
(535=2)
(536=2)
(537=1)
(538=9)
(539=9)
(540=9)
(541=9)
(542=9)
(543=8)
(544=8)
(545=8)
(546=9)
(547=2)
(548=8)
(549=9)
(550=9)
(551=9)
(552=9)
into hoofdgebruik.

recode nature
(220=1002)
(200=1001)
(201=1001)
(202=1001)
(203=1001)
(205=1001)
(206=1001)
(240=1001)
(532=1001)
(164=1002)
(165=1002)
(166=1002)
(204=8003)
(221=1002)
(222=1002)
(223=1002)
(241=7001)
(242=7001)
(243=7001)
(244=7001)
(245=7001)
(246=7001)
(247=7001)
(260=2003)
(261=2003)
(262=2003)
(263=2003)
(264=2003)
(265=2003)
(280=2003)
(281=2003)
(282=2003)
(283=2003)
(284=2003)
(285=2003)
(286=2003)
(287=2003)
(288=2003)
(289=2003)
(290=2003)
(300=2003)
(301=2003)
(302=2003)
(303=2003)
(304=2003)
(305=2003)
(306=2003)
(320=2003)
(321=2003)
(322=2003)
(323=2003)
(324=2003)
(340=2003)
(341=2003)
(342=2003)
(343=2003)
(344=2003)
(345=2003)
(346=2003)
(347=2003)
(348=2003)
(349=2003)
(350=2003)
(351=2003)
(352=2003)
(353=2003)
(354=2003)
(355=2003)
(356=2003)
(357=2003)
(370=2004)
(371=2004)
(372=4006)
(373=4006)
(374=4006)
(375=4006)
(376=2003)
(377=2003)
(378=4001)
(379=2003)
(380=2003)
(381=2003)
(382=2003)
(400=2002)
(401=2002)
(402=2002)
(403=2001)
(404=2001)
(405=2001)
(406=5002)
(407=3001)
(408=2001)
(409=8003)
(410=8003)
(411=2001)
(412=2001)
(413=2001)
(414=2001)
(415=2001)
(420=4003)
(421=4003)
(422=4003)
(423=4003)
(424=4003)
(425=4003)
(426=4003)
(427=4003)
(428=4006)
(429=4006)
(430=4006)
(431=4006)
(432=4006)
(433=4003)
(434=4003)
(440=4002)
(441=4002)
(442=4002)
(443=4002)
(444=4002)
(445=4002)
(446=4002)
(460=4001)
(461=4001)
(462=5002)
(463=5002)
(480=4004)
(481=4004)
(482=4004)
(483=4004)
(484=4004)
(485=4004)
(486=4004)
(487=4004)
(488=4004)
(489=4004)
(500=5001)
(501=5001)
(502=5004)
(503=5004)
(504=5002)
(505=5002)
(506=5002)
(507=5002)
(508=5002)
(509=5002)
(510=9001)
(520=9001)
(521=9001)
(522=9001)
(523=4005)
(524=4005)
(525=4005)
(526=4005)
(527=4005)
(528=4006)
(529=4006)
(530=4006)
(531=4006)
(1=7001)
(2=7001)
(3=7001)
(4=7001)
(5=7001)
(9=6001)
(10=7001)
(11=7001)
(13=7001)
(17=6002)
(18=5001)
(20=5003)
(21=5004)
(25=8002)
(26=8002)
(27=8002)
(28=8002)
(29=8002)
(33=8001)
(34=8001)
(35=6003)
(36=6003)
(38=6003)
(41=6003)
(43=6003)
(44=6003)
(46=6003)
(50=2005)
(51=2005)
(52=2005)
(55=2005)
(59=8002)
(67=9001)
(68=9001)
(69=2005)
(70=9001)
(71=8003)
(72=4006)
(73=4006)
(74=6002)
(76=8002)
(77=9001)
(78=1003)
(79=8003)
(80=9001)
(533=1002)
(534=1002)
(535=2001)
(536=2002)
(537=1002)
(538=9001)
(539=9001)
(540=9001)
(541=9001)
(542=9001)
(543=8003)
(544=8003)
(545=8003)
(546=9001)
(547=2001)
(548=8001)
(549=9001)
(550=9001)
(551=9001)
(552=9001)
into detailgebruik.
