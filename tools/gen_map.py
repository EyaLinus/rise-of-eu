#!/usr/bin/env python3
"""Generates data/map.json: province polygons (Voronoi cells clipped to land),
adjacency and 1444 start ownership.

Usage: python3 tools/gen_map.py path/to/ne_50m_land.geojson path/to/ne_50m_lakes.geojson
Land and lakes: Natural Earth 1:50m (public domain, github.com/nvkelso/natural-earth-vector/geojson).
Projection: tools/mapproj.py.
"""
import json
import os
import sys

from shapely import voronoi_polygons
from shapely import STRtree
from shapely.geometry import MultiPoint, Point, Polygon, box, shape
from shapely.ops import unary_union

# (key, name, lon, lat, owner, dev[, max radius in degrees for desert provinces])
PROVINCES = [
    # England
    ("london", "London", -0.1, 51.5, "ENG", 13),
    ("wessex", "Wessex", -2.6, 51.0, "ENG", 7),
    ("eastanglia", "East Anglia", 1.0, 52.6, "ENG", 8),
    ("midlands", "Midlands", -1.6, 52.6, "ENG", 7),
    ("york", "York", -1.1, 54.0, "ENG", 8),
    ("northumberland", "Northumberland", -2.0, 55.1, "ENG", 5),
    ("wales", "Wales", -3.8, 52.3, "ENG", 5),
    ("cornwall", "Cornwall", -4.8, 50.4, "ENG", 4),
    ("pale", "Dublin", -6.3, 53.4, "ENG", 5),
    ("calais", "Calais", 1.9, 50.9, "ENG", 6),
    ("normandy", "Normandie", 0.0, 49.2, "ENG", 9),
    ("bordeaux", "Guyenne", -0.6, 44.8, "ENG", 8),
    # Scotland / Ireland
    ("lothian", "Lothian", -3.2, 55.9, "SCO", 6),
    ("highlands", "Highlands", -4.5, 57.3, "SCO", 4),
    ("munster", "Munster", -8.5, 52.2, "IRE", 4),
    ("ulster", "Ulster", -6.8, 54.6, "IRE", 3),
    # France
    ("paris", "Paris", 2.35, 48.85, "FRA", 15),
    ("orleans", "Orléans", 1.9, 47.9, "FRA", 8),
    ("champagne", "Champagne", 4.0, 49.0, "FRA", 8),
    ("picardy", "Picardie", 2.3, 49.9, "FRA", 7),
    ("berry", "Berry", 2.4, 47.0, "FRA", 7),
    ("lyon", "Lyon", 4.8, 45.75, "FRA", 8),
    ("auvergne", "Auvergne", 3.1, 45.4, "FRA", 5),
    ("toulouse", "Toulouse", 1.4, 43.6, "FRA", 8),
    ("languedoc", "Languedoc", 3.9, 43.6, "FRA", 7),
    ("poitou", "Poitou", 0.0, 46.4, "FRA", 6),
    ("anjou", "Anjou", 0.2, 47.5, "FRA", 7),
    ("limousin", "Limousin", 1.3, 45.6, "FRA", 5),
    ("dauphine", "Dauphiné", 5.7, 45.0, "FRA", 6),
    # Brittany / Burgundy / Provence / Savoy
    ("rennes", "Rennes", -1.7, 48.1, "BRI", 6),
    ("brest", "Finistère", -4.0, 48.3, "BRI", 4),
    ("dijon", "Dijon", 4.9, 47.3, "BUR", 9),
    ("flanders", "Flandern", 3.2, 51.0, "BUR", 14),
    ("brabant", "Brabant", 4.6, 50.8, "BUR", 11),
    ("holland", "Holland", 4.8, 52.4, "NED", 10),
    ("franchecomte", "Franche-Comté", 6.0, 47.0, "BUR", 6),
    ("luxembourg", "Luxemburg", 6.0, 49.7, "BUR", 5),
    ("provence", "Provence", 5.9, 43.6, "PRV", 7),
    ("savoy", "Savoyen", 6.5, 45.7, "SAV", 6),
    ("piedmont", "Piemont", 7.7, 44.9, "SAV", 7),
    # Iberia
    ("burgos", "Burgos", -3.7, 42.3, "SPA", 8),
    ("toledo", "Toledo", -4.0, 39.8, "SPA", 10),
    ("leon", "León", -5.6, 42.0, "SPA", 6),
    ("galicia", "Galicien", -8.0, 42.8, "SPA", 6),
    ("sevilla", "Sevilla", -6.0, 37.5, "SPA", 10),
    ("murcia", "Murcia", -1.3, 38.1, "SPA", 6),
    ("extremadura", "Extremadura", -6.2, 39.2, "SPA", 5),
    ("biscay", "Biskaya", -3.0, 43.2, "SPA", 6),
    ("zaragoza", "Saragossa", -0.9, 41.6, "ARA", 8),
    ("barcelona", "Barcelona", 1.8, 41.7, "ARA", 11),
    ("valencia", "Valencia", -0.6, 39.4, "ARA", 9),
    ("sardinia", "Sardinien", 9.0, 40.0, "ARA", 4),
    ("sicily", "Sizilien", 14.0, 37.6, "ARA", 8),
    ("pamplona", "Navarra", -1.6, 42.8, "NAV", 5),
    ("lisbon", "Lissabon", -8.8, 39.0, "POR", 10),
    ("porto", "Porto", -8.2, 41.3, "POR", 7),
    ("algarve", "Algarve", -8.0, 37.3, "POR", 4),
    ("granada", "Granada", -3.4, 37.3, "GRA", 9),
    ("malaga", "Málaga", -4.8, 36.8, "GRA", 6),
    # Italy
    ("napoli", "Neapel", 14.6, 40.9, "NAP", 14),
    ("apulia", "Apulien", 16.6, 41.0, "NAP", 8),
    ("calabria", "Kalabrien", 16.3, 39.1, "NAP", 6),
    ("abruzzo", "Abruzzen", 13.9, 42.2, "NAP", 6),
    ("rome", "Rom", 12.5, 42.0, "PAP", 11),
    ("bologna", "Bologna", 11.6, 44.4, "PAP", 8),
    ("ancona", "Ancona", 13.0, 43.4, "PAP", 6),
    ("florence", "Florenz", 11.25, 43.75, "TUS", 11),
    ("siena", "Siena", 11.2, 43.0, "TUS", 6),
    ("milan", "Mailand", 9.2, 45.5, "MLO", 13),
    ("parma", "Parma", 10.3, 44.9, "MLO", 6),
    ("genoa", "Genua", 8.9, 44.4, "GEN", 9),
    ("corsica", "Korsika", 9.1, 42.1, "GEN", 3),
    ("venice", "Venedig", 12.3, 45.5, "VEN", 13),
    ("verona", "Verona", 11.0, 45.5, "VEN", 8),
    ("friuli", "Friaul", 13.2, 46.1, "VEN", 5),
    ("dalmatia", "Dalmatien", 16.2, 43.7, "VEN", 5),
    # Austria / Bohemia / HRE
    ("wien", "Wien", 16.4, 48.2, "HAB", 12),
    ("linz", "Oberösterreich", 14.0, 48.1, "HAB", 7),
    ("steiermark", "Steiermark", 15.4, 47.2, "HAB", 7),
    ("carniola", "Krain", 14.5, 46.2, "HAB", 5),
    ("tirol", "Tirol", 11.4, 47.1, "HAB", 6),
    ("prague", "Prag", 14.6, 50.0, "BOH", 12),
    ("pilsen", "Pilsen", 13.2, 49.6, "BOH", 7),
    ("moravia", "Mähren", 16.8, 49.3, "BOH", 9),
    ("silesia", "Schlesien", 17.0, 51.0, "BOH", 10),
    ("lusatia", "Lausitz", 14.6, 51.3, "BOH", 5),
    ("munich", "München", 11.5, 48.0, "BAV", 9),
    ("regensburg", "Regensburg", 12.2, 49.0, "BAV", 7),
    ("dresden", "Dresden", 13.4, 50.9, "SAX", 8),
    ("leipzig", "Leipzig", 12.2, 51.5, "SAX", 8),
    ("berlin", "Brandenburg", 13.3, 52.5, "BRA", 7),
    ("cologne", "Köln", 7.0, 50.9, "KOL", 9),
    ("palatinate", "Pfalz", 8.4, 49.5, "PAL", 8),
    ("swabia", "Schwaben", 9.4, 48.6, "WUR", 8),
    ("nuremberg", "Nürnberg", 10.7, 49.6, "NUR", 8),
    ("hesse", "Hessen", 9.2, 50.7, "HES", 6),
    ("brunswick", "Braunschweig", 10.2, 52.3, "LUN", 7),
    ("bremen", "Bremen", 8.6, 53.1, "LUN", 6),
    ("hamburg", "Hamburg", 10.4, 53.5, "HSA", 8),
    ("pomerania", "Pommern", 14.6, 53.6, "POM", 6),
    ("mecklenburg", "Mecklenburg", 12.0, 53.7, "POM", 5),
    ("bern", "Bern", 7.4, 46.8, "SWI", 7),
    ("zurich", "Zürich", 8.7, 47.4, "SWI", 7),
    # East
    ("prussia", "Preußen", 20.6, 54.5, "TEU", 8),
    ("marienburg", "Marienburg", 18.6, 53.9, "TEU", 7),
    ("krakow", "Krakau", 20.0, 50.1, "POL", 11),
    ("poznan", "Großpolen", 17.0, 52.4, "POL", 9),
    ("warsaw", "Masowien", 21.2, 52.3, "POL", 8),
    ("lwow", "Rotruthenien", 24.0, 49.7, "POL", 7),
    ("vilnius", "Wilna", 25.3, 54.8, "LIT", 9),
    ("minsk", "Minsk", 27.6, 53.8, "LIT", 6),
    ("kiev", "Kiew", 30.5, 50.4, "LIT", 8),
    ("smolensk", "Smolensk", 32.0, 54.7, "LIT", 7),
    ("volhynia", "Wolhynien", 25.5, 51.0, "LIT", 5),
    ("chernigov", "Tschernigow", 31.5, 51.9, "LIT", 5),
    ("buda", "Buda", 19.1, 47.4, "HUN", 12),
    ("kassa", "Oberungarn", 21.3, 48.6, "HUN", 7),
    ("transylvania", "Siebenbürgen", 23.8, 46.6, "HUN", 8),
    ("croatia", "Kroatien", 15.8, 45.6, "HUN", 6),
    ("pressburg", "Pressburg", 17.6, 48.3, "HUN", 7),
    ("temes", "Temesvar", 21.2, 45.8, "HUN", 6),
    ("slavonia", "Slawonien", 18.3, 45.6, "HUN", 5),
    # Russia
    ("moscow", "Moskau", 37.6, 55.75, "RUS", 12),
    ("tver", "Twer", 35.3, 56.9, "RUS", 7),
    ("yaroslavl", "Jaroslawl", 39.6, 57.8, "RUS", 6),
    ("vladimir", "Wladimir", 41.0, 56.2, "RUS", 6),
    ("nizhny", "Nischni Nowgorod", 44.0, 56.3, "RUS", 6),
    ("tula", "Tula", 37.4, 54.0, "RUS", 6),
    ("vologda", "Wologda", 40.2, 59.4, "RUS", 4),
    ("ryazan", "Rjasan", 40.5, 54.4, "RYA", 6),
    ("novgorod", "Nowgorod", 31.6, 58.5, "NOV", 9),
    ("pskov", "Pskow", 28.6, 57.6, "NOV", 6),
    ("karelia", "Karelien", 33.0, 61.6, "NOV", 3),
    ("beloozero", "Beloosero", 37.0, 60.0, "NOV", 3),
    ("kazan", "Kasan", 49.1, 55.8, "KAZ", 7),
    ("crimea", "Krim", 34.2, 45.1, "CRI", 6),
    ("zaporozhia", "Wildes Feld", 35.5, 47.5, "CRI", 3),
    ("riga", "Riga", 24.6, 56.9, "LIV", 7),
    ("reval", "Reval", 25.3, 58.9, "LIV", 5),
    # Scandinavia (Kalmar Union)
    ("copenhagen", "Kopenhagen", 12.0, 55.5, "DAN", 10),
    ("jutland", "Jütland", 9.2, 56.2, "DAN", 7),
    ("holstein", "Holstein", 9.8, 54.3, "DAN", 6),
    ("scania", "Schonen", 13.6, 56.0, "DAN", 6),
    ("oslo", "Oslo", 10.5, 60.0, "DAN", 5),
    ("bergen", "Bergen", 6.2, 60.6, "DAN", 4),
    ("stockholm", "Stockholm", 17.6, 59.6, "DAN", 8),
    ("gotaland", "Götaland", 14.0, 57.8, "DAN", 6),
    ("turku", "Finnland", 23.5, 61.0, "DAN", 4),
    ("dalarna", "Dalarna", 15.0, 61.0, "DAN", 3),
    # Balkans
    ("edirne", "Edirne", 26.6, 41.8, "TUR", 10),
    ("sofia", "Sofia", 23.6, 42.7, "TUR", 7),
    ("skopje", "Makedonien", 21.8, 41.4, "TUR", 6),
    ("thessaly", "Thessalien", 22.4, 39.6, "TUR", 5),
    ("varna", "Varna", 27.5, 43.2, "TUR", 5),
    ("constantinople", "Konstantinopel", 28.9, 41.1, "BYZ", 14),
    ("morea", "Morea", 22.2, 37.6, "BYZ", 5),
    ("serbia", "Serbien", 20.7, 44.0, "SER", 6),
    ("bosnia", "Bosnien", 18.0, 44.1, "BOS", 5),
    ("wallachia", "Walachei", 25.6, 44.6, "WAL", 7),
    ("moldavia", "Moldau", 27.2, 47.0, "MOL", 6),
    ("albania", "Albanien", 20.0, 41.1, "ALB", 4),
    # --- the south and east (added after the first 161 provinces so their ids stay stable) ---
    # Anatolia
    ("bursa", "Bursa", 29.06, 40.18, "TUR", 10),
    ("izmit", "Kocaeli", 30.1, 40.75, "TUR", 6),
    ("saruhan", "Saruhan", 27.6, 38.75, "TUR", 6),
    ("aydin", "Aydın", 28.0, 37.85, "TUR", 7),
    ("mentese", "Menteşe", 28.6, 37.05, "TUR", 4),
    ("germiyan", "Germiyan", 30.0, 39.4, "TUR", 5),
    ("hamid", "Hamid", 30.7, 37.9, "TUR", 4),
    ("teke", "Teke", 30.7, 36.95, "TUR", 5),
    ("ankara", "Ankara", 32.85, 39.93, "TUR", 7),
    ("amasya", "Amasya", 35.83, 40.65, "TUR", 6),
    ("sivas", "Sivas", 37.0, 39.75, "TUR", 5),
    ("kastamonu", "Kastamonu", 33.78, 41.38, "CND", 5),
    ("sinop", "Sinope", 35.15, 42.0, "CND", 4),
    ("konya", "Konya", 32.48, 37.87, "KAR", 8),
    ("larende", "Larende", 33.3, 37.0, "KAR", 4),
    ("aksaray", "Aksaray", 34.0, 38.4, "KAR", 4),
    ("kayseri", "Kayseri", 35.48, 38.73, "KAR", 6),
    ("icel", "İçel", 33.9, 36.4, "KAR", 3),
    ("marash", "Maraş", 36.93, 37.58, "DUL", 5),
    ("adana", "Adana", 35.32, 37.0, "MAM", 6),
    ("malatya", "Malatya", 38.3, 38.35, "MAM", 5),
    ("trebizond", "Trapezunt", 39.72, 41.0, "TRE", 7),
    ("diyarbakir", "Diyarbakır", 40.22, 37.91, "AKK", 7),
    ("urfa", "Urfa", 38.8, 37.15, "AKK", 4),
    ("erzincan", "Erzincan", 39.5, 39.75, "AKK", 4),
    ("erzurum", "Erzurum", 41.27, 39.9, "QAR", 4),
    ("van", "Van", 43.38, 38.5, "QAR", 5),
    ("mosul", "Mossul", 43.13, 36.34, "QAR", 6, 2.2),
    ("yerevan", "Eriwan", 44.5, 40.18, "QAR", 5),
    ("tabriz", "Täbris", 46.3, 38.08, "QAR", 10, 2.2),
    # Caucasus
    ("tbilisi", "Tiflis", 44.8, 41.7, "GEO", 8),
    ("imereti", "Imeretien", 42.7, 42.27, "GEO", 5),
    ("kakheti", "Kachetien", 46.0, 41.95, "GEO", 4),
    ("abkhazia", "Abchasien", 41.0, 43.0, "GEO", 3),
    ("shamakhi", "Schemacha", 48.64, 40.63, "SHI", 7),
    ("derbent", "Derbent", 48.29, 42.06, "SHI", 5),
    ("circassia", "Tscherkessien", 39.5, 44.6, "CIR", 4),
    ("kabarda", "Kabarda", 43.6, 43.5, "CIR", 3),
    # Levant, Egypt, Cyrenaica (Mamluks)
    ("aleppo", "Aleppo", 37.16, 36.2, "MAM", 9),
    ("tripoli_sy", "Tripolis (Syrien)", 35.85, 34.43, "MAM", 6),
    ("damascus", "Damaskus", 36.3, 33.5, "MAM", 10, 2.2),
    ("jerusalem", "Jerusalem", 35.2, 31.78, "MAM", 7, 2.2),
    ("cairo", "Kairo", 31.24, 30.04, "MAM", 16, 2.2),
    ("alexandria", "Alexandria", 29.92, 31.2, "MAM", 10),
    ("damietta", "Damiette", 31.8, 31.42, "MAM", 6),
    ("upper_egypt", "Oberägypten", 30.8, 28.3, "MAM", 5, 2.2),
    ("marmarica", "Marmarika", 25.0, 31.6, "MAM", 2, 2.2),
    ("barqa", "Barka", 20.07, 32.1, "MAM", 3, 2.2),
    # Maghreb
    ("sirte", "Syrte", 16.6, 31.2, "TUN", 2, 2.2),
    ("tripoli", "Tripolis", 13.18, 32.9, "TUN", 6, 2.2),
    ("gabes", "Gabès", 10.1, 33.9, "TUN", 3, 2.2),
    ("kairouan", "Kairouan", 10.1, 35.68, "TUN", 6, 2.2),
    ("tunis", "Tunis", 10.18, 36.8, "TUN", 12),
    ("constantine", "Konstantine", 6.61, 36.36, "TUN", 6),
    ("bejaia", "Bejaia", 5.08, 36.75, "TUN", 5),
    ("algiers", "Algier", 3.06, 36.75, "TLE", 6),
    ("oran", "Oran", -0.63, 35.7, "TLE", 5),
    ("tlemcen", "Tlemcen", -1.32, 34.88, "TLE", 8, 2.2),
    ("rif", "Rif", -3.9, 35.1, "MOR", 3),
    ("tangier", "Tanger", -5.8, 35.77, "MOR", 5),
    ("fez", "Fès", -5.0, 34.03, "MOR", 12),
    ("rabat", "Salé", -6.84, 34.02, "MOR", 5),
    ("marrakesh", "Marrakesch", -8.0, 31.63, "MOR", 9, 2.2),
    ("sous", "Sous", -9.4, 30.2, "MOR", 3, 2.2),
    # Eastern Mediterranean islands
    ("crete", "Kreta", 24.9, 35.25, "VEN", 6),
    ("cyprus", "Zypern", 33.36, 35.1, "CYP", 6),
    ("rhodes", "Rhodos", 28.0, 36.2, "KNI", 4),
    # --- the New World (added after the first 228 provinces; ids stay stable). Owner NAT = uncolonized
    # native land (scripts/core/colonial.gd); AZT TLX ZAP TAR MAY KIC IRO are native realms.
    # Mesoamerica
    ("tenochtitlan", "Tenochtitlan", -99.1, 19.4, "AZT", 14),
    ("tlaxcala", "Tlaxcala", -97.9, 19.1, "TLX", 6),
    ("cempoala", "Cempoala", -96.6, 19.7, "AZT", 6),
    ("huasteca", "Huasteca", -98.6, 21.7, "AZT", 5),
    ("tlapan", "Tlapan", -99.6, 17.6, "AZT", 4),
    ("oaxaca", "Oaxaca", -96.7, 17.0, "ZAP", 7),
    ("tehuantepec", "Tehuantepec", -94.9, 16.6, "ZAP", 4),
    ("michoacan", "Michoacán", -101.4, 19.4, "TAR", 9),
    ("jalisco", "Jalisco", -103.0, 20.6, "NAT", 3),
    ("bajio", "Bajío", -100.6, 21.3, "NAT", 2),
    ("zacatecas", "Zacatecas", -102.0, 23.3, "NAT", 2),
    ("tamaulipas", "Tamaulipas", -98.4, 23.8, "NAT", 2),
    ("nuevo_leon", "Nuevo León", -100.0, 25.6, "NAT", 1),
    ("coahuila", "Coahuila", -102.2, 27.6, "NAT", 1, 4.0),
    ("tabasco", "Tabasco", -92.9, 18.0, "NAT", 3),
    ("chiapas", "Chiapas", -92.5, 16.4, "NAT", 3),
    ("yucatan", "Mayapán", -89.4, 20.6, "MAY", 6),
    ("campeche", "Campeche", -90.4, 19.0, "MAY", 4),
    ("chetumal", "Chetumal", -88.5, 18.6, "MAY", 3),
    ("peten", "Petén", -89.9, 16.8, "MAY", 4),
    ("guatemala", "Q'umarkaj", -91.2, 15.0, "KIC", 6),
    ("cuscatlan", "Cuscatlán", -89.2, 13.8, "NAT", 3),
    ("honduras", "Honduras", -87.2, 14.7, "NAT", 3),
    ("mosquitia", "Mosquitia", -84.6, 14.5, "NAT", 1),
    ("nicaragua", "Nicaragua", -85.9, 12.4, "NAT", 3),
    ("costa_rica", "Costa Rica", -84.0, 10.0, "NAT", 2),
    ("veragua", "Veragua", -81.5, 8.6, "NAT", 1),
    ("darien", "Darién", -79.6, 8.9, "NAT", 2, 1.6),
    # Caribbean
    ("havana", "Havanna", -82.4, 22.8, "NAT", 3),
    ("camaguey", "Camagüey", -78.4, 21.6, "NAT", 2),
    ("oriente", "Oriente", -76.0, 20.3, "NAT", 3),
    ("jamaica", "Jamaika", -77.3, 18.1, "NAT", 2),
    ("ayiti", "Ayiti", -72.6, 19.0, "NAT", 3),
    ("quisqueya", "Quisqueya", -70.0, 18.8, "NAT", 4),
    ("boriken", "Borikén", -66.4, 18.2, "NAT", 3),
    ("antilles", "Kleine Antillen", -61.4, 15.6, "NAT", 1),
    ("lucayas", "Lucayas", -77.8, 24.4, "NAT", 1, 2.0),
    ("trinidad", "Trinidad", -61.3, 10.4, "NAT", 1, 0.7),
    # North America: Gulf and the south-east
    ("florida", "Florida", -81.6, 28.0, "NAT", 2),
    ("apalachee", "Apalachee", -84.3, 30.6, "NAT", 2),
    ("maubila", "Maubila", -87.9, 31.5, "NAT", 2),
    ("natchez", "Natchez", -91.3, 32.0, "NAT", 3),
    ("delta", "Mississippi-Delta", -90.6, 29.8, "NAT", 2),
    ("caddo", "Caddo", -94.4, 32.4, "NAT", 3),
    ("karankawa", "Karankawa", -96.9, 29.2, "NAT", 1),
    ("hasinai", "Hasinai", -97.4, 32.4, "NAT", 1),
    ("apacheria", "Apachería", -101.2, 31.0, "NAT", 1, 4.0),
    ("llano", "Llano Estacado", -101.5, 34.6, "NAT", 1, 4.0),
    ("coosa", "Coosa", -85.6, 33.6, "NAT", 3),
    ("cofitachequi", "Cofitachequi", -80.8, 33.9, "NAT", 3),
    ("cherokee", "Cherokee", -83.4, 35.7, "NAT", 3),
    ("chickasaw", "Chickasaw", -88.8, 34.8, "NAT", 2),
    ("quapaw", "Quapaw", -92.2, 35.2, "NAT", 2),
    ("wichita", "Wichita", -97.6, 36.5, "NAT", 1),
    # the east coast
    ("secotan", "Secotan", -77.2, 35.6, "NAT", 2),
    ("powhatan", "Powhatan", -77.4, 37.7, "NAT", 3),
    ("susquehannock", "Susquehannock", -76.6, 40.2, "NAT", 2),
    ("lenape", "Lenapehoking", -74.7, 39.9, "NAT", 2),
    ("mahican", "Mahican", -73.7, 42.7, "NAT", 2),
    ("massachusett", "Massachusett", -71.3, 42.5, "NAT", 3),
    ("abenaki", "Abenaki", -71.4, 44.3, "NAT", 2),
    ("mikmaq", "Mi'kma'ki", -63.6, 45.2, "NAT", 1),
    ("gaspe", "Gaspé", -66.2, 48.0, "NAT", 1),
    ("newfoundland", "Neufundland", -56.0, 48.6, "NAT", 1),
    ("labrador", "Labrador", -61.0, 53.6, "NAT", 1, 4.0),
    # Iroquoia, the Great Lakes and the St. Lawrence
    ("onondaga", "Onondaga", -76.1, 43.0, "IRO", 5),
    ("seneca", "Seneca", -78.0, 42.6, "IRO", 3),
    ("stadacona", "Stadacona", -71.2, 46.9, "NAT", 2),
    ("hochelaga", "Hochelaga", -73.6, 45.6, "NAT", 2),
    ("saguenay", "Saguenay", -71.0, 49.6, "NAT", 1, 4.0),
    ("wendake", "Wendake", -79.6, 44.6, "NAT", 3),
    ("algonquin", "Algonkin", -77.4, 46.8, "NAT", 1),
    ("nipissing", "Nipissing", -81.6, 47.3, "NAT", 1),
    ("erie", "Erie", -81.8, 41.0, "NAT", 2),
    ("shawnee", "Shawnee", -83.4, 38.6, "NAT", 2),
    ("miami", "Miami", -86.0, 40.6, "NAT", 1),
    ("cahokia", "Cahokia", -90.0, 38.6, "NAT", 3),
    ("illinois", "Illinois", -89.2, 41.6, "NAT", 2),
    ("osage", "Osage", -94.4, 37.9, "NAT", 1),
    ("michigan", "Anishinaabe", -84.6, 43.6, "NAT", 1),
    ("menominee", "Menominee", -89.0, 44.9, "NAT", 1),
    ("ioway", "Ioway", -93.4, 41.8, "NAT", 1),
    ("pawnee", "Pawnee", -98.6, 41.0, "NAT", 1, 4.0),
    ("ojibwe", "Ojibwe", -93.4, 46.9, "NAT", 1),
    ("lakota", "Lakota", -100.6, 44.6, "NAT", 1, 4.0),
    ("dakota", "Dakota", -97.2, 47.6, "NAT", 1),
    ("nipigon", "Nipigon", -87.4, 49.6, "NAT", 1, 4.0),
    ("assiniboine", "Assiniboine", -98.0, 51.0, "NAT", 1, 4.0),
    # the far north
    ("cree", "Cree", -80.4, 51.0, "NAT", 1, 4.0),
    ("eeyou", "Eeyou", -75.6, 51.6, "NAT", 1, 4.0),
    ("nitassinan", "Nitassinan", -66.4, 51.4, "NAT", 1, 4.0),
    ("moosonee", "Moosonee", -85.4, 53.8, "NAT", 1, 4.0),
    ("kiwetinok", "Kiwetinok", -95.0, 55.4, "NAT", 1, 4.5),
    ("ungava", "Ungava", -71.0, 57.4, "NAT", 1, 4.5),
    ("nunavik", "Nunavik", -76.0, 60.6, "NAT", 1, 4.5),
    # --- West Africa (appended so every older id stays stable; "wa" + "nw" in map.json) ---
    ("arguin", "Arguin", -16.2, 20.4, "NAT", 1, 2.4),
    ("adrar", "Adrar", -12.0, 20.4, "NAT", 1, 2.9),
    ("taghaza", "Taghaza", -5.0, 23.5, "NAT", 1, 2.6),
    ("waalo", "Waalo", -15.8, 16.4, "JOL", 3),
    ("jolof", "Jolof", -15.0, 15.2, "JOL", 6),
    ("cayor", "Kayor", -16.8, 14.8, "JOL", 4),
    ("futa_toro", "Futa Toro", -13.2, 15.9, "NAT", 2),
    ("gambia", "Gambia", -15.3, 13.4, "NAT", 3),
    ("casamance", "Casamance", -15.6, 12.2, "NAT", 2),
    ("futa_jallon", "Futa Djallon", -12.2, 11.2, "NAT", 3),
    ("sierra_leone", "Sierra Leone", -12.8, 8.7, "NAT", 2),
    ("pepper_coast", "Pfefferküste", -9.8, 6.6, "NAT", 2),
    ("ivory_coast", "Elfenbeinküste", -5.6, 5.8, "NAT", 2),
    ("kong", "Kong", -4.6, 9.2, "NAT", 2),
    ("gold_coast", "Goldküste", -1.4, 5.6, "NAT", 3),
    ("akan", "Akan", -1.6, 7.4, "NAT", 3),
    ("allada", "Allada", 2.2, 6.8, "NAT", 3),
    ("oyo", "Oyo", 3.9, 8.4, "NAT", 4),
    ("borgu", "Borgu", 2.6, 10.4, "NAT", 2),
    ("benin", "Benin", 5.8, 6.6, "BEN", 7),
    ("niger_delta", "Nigerdelta", 6.6, 5.0, "BEN", 2),
    ("nupe", "Nupe", 6.2, 9.4, "NAT", 3),
    ("hausa", "Kano", 8.5, 12.0, "KAN", 6),
    ("niani", "Niani", -9.4, 11.4, "MAL", 6),
    ("kaarta", "Kaarta", -10.2, 14.4, "MAL", 3),
    ("segu", "Ségou", -7.0, 13.0, "MAL", 4),
    ("djenne", "Djenné", -4.4, 14.2, "MAL", 7),
    ("timbuktu", "Timbuktu", -3.0, 16.8, "MAL", 7, 2.4),
    ("walata", "Walata", -7.0, 17.6, "MAL", 2, 2.9),
    ("mossi", "Mossi", -1.5, 12.2, "NAT", 4),
    ("gao", "Gao", 0.0, 16.3, "SON", 7, 2.4),
    ("dendi", "Dendi", 3.2, 12.4, "SON", 3),
    # --- the Middle East and the Horn of Africa (appended after West Africa so every older id stays stable;
    # "east" in map.json: Old World, known from the start, not colonial) ---
    # Mesopotamia
    ("baghdad", "Bagdad", 44.4, 33.3, "QAR", 10, 2.2),
    ("basra", "Basra", 47.6, 30.6, "QAR", 6, 2.0),
    ("kirkuk", "Kirkuk", 44.4, 35.5, "QAR", 4, 2.0),
    ("raqqa", "Raqqa", 39.0, 35.95, "MAM", 3, 2.0),
    # Persia
    ("ardabil", "Ardabil", 48.3, 38.25, "SAF", 5),
    ("gilan", "Gilan", 49.6, 37.2, "MAZ", 5),
    ("mazandaran", "Masandaran", 52.6, 36.5, "MAZ", 5),
    ("qazvin", "Qazvin", 50.0, 36.27, "QAR", 6),
    ("hamadan", "Hamadan", 48.5, 34.8, "QAR", 6),
    ("kermanshah", "Kermanschah", 47.06, 34.3, "QAR", 4),
    ("luristan", "Luristan", 48.3, 33.4, "QAR", 3),
    ("khuzestan", "Chusistan", 48.7, 31.3, "QAR", 5, 2.0),
    ("rey", "Rey", 51.4, 35.6, "TIM", 6, 2.2),
    ("isfahan", "Isfahan", 51.67, 32.65, "TIM", 10, 2.2),
    ("yazd", "Yazd", 54.36, 31.9, "TIM", 5, 2.2),
    ("fars", "Fars", 52.53, 29.6, "TIM", 9, 2.2),
    ("bushehr", "Buschehr", 50.84, 28.97, "TIM", 3, 1.8),
    ("laristan", "Laristan", 53.1, 28.3, "HOR", 3, 1.8),
    ("hormuz", "Hormus", 54.7, 27.0, "HOR", 7, 1.8),
    # Arabia
    ("hasa", "al-Hasa", 49.6, 25.4, "HOR", 4, 2.2),
    ("sinai", "Sinai", 33.8, 29.3, "MAM", 1, 1.8),
    ("tabuk", "Tabuk", 36.6, 28.4, "MAM", 2, 2.2),
    ("medina", "Medina", 39.6, 24.47, "HJZ", 5, 2.2),
    ("mecca", "Mekka", 39.83, 21.42, "HJZ", 8, 2.2),
    ("asir", "Asir", 42.5, 18.2, "HJZ", 3, 2.2),
    ("tihama", "Tihama", 43.3, 14.6, "YEM", 5, 2.0),
    ("sanaa", "Sanaa", 44.2, 15.35, "YEM", 7, 1.8),
    ("aden", "Aden", 45.0, 12.9, "YEM", 7, 1.8),
    ("hadramaut", "Hadramaut", 48.8, 15.9, "YEM", 3, 2.6),
    ("dhofar", "Dhofar", 53.8, 17.2, "YEM", 2, 2.4),
    # the Nile and the Red Sea
    ("aswan", "Assuan", 32.9, 24.1, "MAM", 3, 2.0),
    ("suakin", "Suakin", 37.2, 19.1, "MAM", 3, 2.0),
    ("dongola", "Dongola", 30.5, 19.2, "ALO", 2, 2.4),
    ("alwa", "Alwa", 32.6, 15.6, "ALO", 4, 2.2),
    ("sennar", "Sennar", 33.6, 13.0, "ALO", 4, 2.2),
    # Ethiopia
    ("medri_bahri", "Medri Bahri", 38.9, 15.4, "ETH", 4, 2.0),
    ("tigray", "Tigray", 39.0, 13.8, "ETH", 6, 1.8),
    ("begemder", "Begemder", 37.6, 12.4, "ETH", 6, 1.8),
    ("gojjam", "Gojjam", 37.3, 10.6, "ETH", 5, 1.8),
    ("amhara", "Amhara", 39.4, 11.2, "ETH", 7, 1.8),
    ("shewa", "Schoa", 38.8, 9.0, "ETH", 6, 1.8),
    ("damot", "Damot", 36.6, 8.2, "ETH", 3, 2.0),
    # Adal and the Somali coast
    ("danakil", "Danakil", 41.2, 13.0, "ADA", 2, 2.0),
    ("harar", "Harar", 42.1, 9.3, "ADA", 7, 1.8),
    ("zeila", "Zeila", 43.4, 11.2, "ADA", 5, 1.8),
    ("berbera", "Berbera", 45.0, 10.2, "ADA", 3, 2.0),
    ("ogaden", "Ogaden", 44.0, 7.4, "ADA", 2, 2.6),
    # --- Africa south of the Sahara (appended after the east block so every older id stays stable;
    # "af" in map.json, also "nw" and "wa": overseas/colonial like West Africa). South of the Sahara the
    # radius is 6° so the Voronoi cells fill the land without wasteland gaps ---
    # the Sahara and the Sudan belt
    ("fezzan", "Fessan", 14.4, 26.0, "NAT", 2, 4.4),
    ("air", "Aïr", 8.0, 17.5, "NAT", 2, 3.6),
    ("tibesti", "Tibesti", 18.5, 20.8, "NAT", 1, 4.6),
    ("bornu", "Bornu", 12.3, 12.6, "BOR", 7, 6.0),
    ("kanem", "Kanem", 15.6, 14.6, "BOR", 3, 3.0),
    ("bagirmi", "Bagirmi", 17.2, 11.0, "NAT", 2, 6.0),
    ("wadai", "Wadai", 21.0, 13.5, "NAT", 2, 6.0),
    ("darfur", "Darfur", 24.6, 13.0, "DAR", 5, 6.0),
    ("kordofan", "Kordofan", 29.8, 12.8, "NAT", 2, 6.0),
    ("adamawa", "Adamaua", 13.0, 8.0, "NAT", 2, 6.0),
    ("cameroon", "Kamerun", 10.0, 4.3, "NAT", 2, 6.0),
    # the Somali coast and southern Ethiopia
    ("majerteen", "Majerteen", 48.6, 9.6, "NAT", 2, 6.0),
    ("hobyo", "Hobyo", 47.2, 5.6, "AJU", 3, 6.0),
    ("mogadishu", "Mogadischu", 45.3, 2.3, "AJU", 7, 6.0),
    ("juba", "Jubaland", 42.3, 0.2, "AJU", 2, 6.0),
    ("borana", "Borana", 39.0, 4.6, "NAT", 1, 6.0),
    ("kaffa", "Kaffa", 35.8, 6.6, "NAT", 3, 6.0),
    ("bale", "Bale", 40.3, 7.2, "NAT", 2, 6.0),
    # the Swahili coast
    ("malindi", "Malindi", 40.0, -2.8, "MLD", 5, 6.0),
    ("mombasa", "Mombasa", 39.5, -4.2, "MBA", 6, 6.0),
    ("zanzibar", "Sansibar", 39.35, -6.1, "KIL", 5, 0.35),
    ("bagamoyo", "Bagamoyo", 38.4, -6.5, "NAT", 2, 6.0),
    ("kilwa", "Kilwa", 39.3, -8.8, "KIL", 7, 6.0),
    ("mozambique", "Mosambik", 40.2, -14.0, "KIL", 3, 6.0),
    ("sofala", "Sofala", 34.8, -19.6, "KIL", 4, 6.0),
    ("inhambane", "Inhambane", 34.9, -23.4, "NAT", 2, 6.0),
    # East Africa and the Great Lakes
    ("kenya", "Kikuyu-Hochland", 37.0, -0.6, "NAT", 2, 6.0),
    ("maasai", "Massaisteppe", 36.6, -3.9, "NAT", 1, 6.0),
    ("unyamwezi", "Unyamwezi", 33.2, -5.4, "NAT", 2, 6.0),
    ("yao", "Yao", 37.0, -11.0, "NAT", 2, 6.0),
    ("bunyoro", "Bunyoro", 31.4, 1.5, "KIT", 5, 6.0),
    ("buganda", "Buganda", 32.5, 0.2, "NAT", 3, 6.0),
    ("rwanda", "Ruanda", 29.9, -2.0, "NAT", 3, 6.0),
    ("sudd", "Sudd", 30.6, 7.5, "NAT", 1, 6.0),
    ("azande", "Azande", 26.0, 4.8, "NAT", 1, 6.0),
    ("ituri", "Ituri", 28.6, 1.0, "NAT", 1, 6.0),
    # Kongo and Central Africa
    ("kongo", "Kongo", 14.4, -6.0, "KON", 8, 6.0),
    ("loango", "Loango", 12.2, -4.0, "NAT", 3, 6.0),
    ("ndongo", "Ndongo", 15.5, -9.2, "NDO", 4, 6.0),
    ("benguela", "Benguela", 14.2, -12.8, "NAT", 2, 6.0),
    ("yaka", "Kwango", 17.8, -6.4, "NAT", 2, 6.0),
    ("tio", "Tio", 16.0, -2.6, "NAT", 3, 6.0),
    ("ogowe", "Ogowe", 11.2, -0.6, "NAT", 1, 6.0),
    ("ubangi", "Ubangi", 18.6, 3.2, "NAT", 1, 6.0),
    ("congo_basin", "Kongobecken", 21.0, -0.8, "NAT", 1, 6.0),
    ("kuba", "Kuba", 21.8, -5.2, "NAT", 2, 6.0),
    ("luba", "Luba", 25.8, -7.4, "NAT", 3, 6.0),
    ("lunda", "Lunda", 22.5, -10.0, "NAT", 2, 6.0),
    ("katanga", "Katanga", 27.5, -11.0, "NAT", 2, 6.0),
    ("maniema", "Maniema", 26.0, -3.0, "NAT", 1, 6.0),
    # Mutapa and southern Africa
    ("mutapa", "Mutapa", 31.2, -16.6, "MUT", 6, 6.0),
    ("zimbabwe", "Groß-Simbabwe", 30.9, -20.2, "MUT", 5, 6.0),
    ("maravi", "Maravi", 33.8, -13.5, "NAT", 2, 6.0),
    ("luangwa", "Luangwa", 30.2, -12.8, "NAT", 1, 6.0),
    ("lozi", "Barotseland", 23.5, -15.5, "NAT", 2, 6.0),
    ("ovambo", "Ovambo", 16.0, -17.8, "NAT", 2, 6.0),
    ("okavango", "Okavango", 22.5, -19.8, "NAT", 1, 6.0),
    ("damaraland", "Damaraland", 16.5, -22.0, "NAT", 1, 6.0),
    ("kalahari", "Kalahari", 22.0, -24.0, "NAT", 1, 6.0),
    ("namaqua", "Namaland", 18.0, -28.0, "NAT", 1, 6.0),
    ("cape", "Kap", 19.0, -33.6, "NAT", 1, 6.0),
    ("karoo", "Karoo", 22.5, -31.5, "NAT", 1, 6.0),
    ("xhosa", "Xhosa", 27.0, -32.4, "NAT", 2, 6.0),
    ("natal", "Natal", 30.2, -28.8, "NAT", 2, 6.0),
    ("highveld", "Hochveld", 27.0, -26.6, "NAT", 2, 6.0),
    ("limpopo", "Limpopo", 29.5, -23.6, "NAT", 2, 6.0),
    ("delagoa", "Delagoa", 32.6, -25.6, "NAT", 2, 6.0),
    # Madagascar
    ("boina", "Boina", 46.4, -16.2, "NAT", 2, 6.0),
    ("betsimisaraka", "Betsimisaraka", 49.0, -16.8, "NAT", 2, 6.0),
    ("imerina", "Imerina", 47.4, -19.2, "NAT", 3, 6.0),
    ("menabe", "Menabe", 44.6, -20.8, "NAT", 2, 6.0),
    ("androy", "Androy", 46.0, -24.2, "NAT", 1, 6.0),
    # --- South America and a finer North American east coast (appended after Africa so every older id
    # stays stable; "sa" + "nw" in map.json: overseas/colonial, region "america") ---
    # the North American east coast (finer cut: colonial landing places)
    ("calusa", "Calusa", -81.3, 26.0, "NAT", 2, 2.0),
    ("timucua", "Timucua", -82.0, 30.0, "NAT", 2),
    ("guale", "Guale", -81.6, 31.8, "NAT", 2),
    ("tuscarora", "Tuscarora", -78.6, 35.4, "NAT", 2),
    ("nanticoke", "Nanticoke", -75.7, 38.6, "NAT", 1),
    ("munsee", "Manahatta", -73.9, 41.0, "NAT", 2),
    ("pequot", "Pequot", -72.4, 41.6, "NAT", 2),
    ("wampanoag", "Wampanoag", -70.7, 41.8, "NAT", 2),
    ("penobscot", "Penobscot", -68.8, 44.9, "NAT", 1),
    ("wolastoqiyik", "Wolastoqiyik", -66.4, 46.2, "NAT", 1),
    # the Caribbean coast of South America and the Guianas
    ("tairona", "Tairona", -73.9, 10.9, "NAT", 3, 6.0),
    ("calamari", "Calamarí", -75.2, 10.1, "NAT", 2, 6.0),
    ("zenu", "Zenú", -75.8, 8.5, "NAT", 2, 6.0),
    ("antioquia", "Antioquia", -75.6, 6.4, "NAT", 2, 6.0),
    ("coquivacoa", "Coquivacoa", -71.8, 10.4, "NAT", 2, 6.0),
    ("caracas", "Caracas", -67.2, 10.1, "NAT", 2, 6.0),
    ("cumana", "Cumaná", -64.0, 10.0, "NAT", 1, 6.0),
    ("llanos", "Llanos", -68.8, 7.2, "NAT", 1, 6.0),
    ("orinoco", "Orinoco-Delta", -61.8, 8.4, "NAT", 1, 6.0),
    ("guayana", "Guayana", -58.6, 6.0, "NAT", 1, 6.0),
    ("suriname", "Suriname", -55.6, 4.6, "NAT", 1, 6.0),
    ("cayenne", "Cayenne", -53.0, 4.0, "NAT", 1, 6.0),
    ("roraima", "Roraima", -62.4, 3.8, "NAT", 1, 6.0),
    # the Muisca and the northern Andes
    ("bacata", "Bacatá", -74.1, 4.6, "MUI", 6, 6.0),
    ("hunza", "Hunza", -73.0, 5.8, "MUI", 5, 6.0),
    ("cauca", "Popayán", -76.6, 2.4, "NAT", 2, 6.0),
    ("quito", "Quito", -78.5, -0.2, "QTO", 5, 6.0),
    ("guayaquil", "Huancavilca", -80.0, -1.8, "NAT", 3, 6.0),
    ("canari", "Tumipampa", -78.9, -2.9, "NAT", 3, 6.0),
    # Chimor and the coast of Peru
    ("tumbes", "Tumbes", -80.5, -4.6, "CHM", 2, 6.0),
    ("lambayeque", "Lambayeque", -79.9, -6.6, "CHM", 4, 6.0),
    ("chan_chan", "Chan Chan", -79.0, -8.1, "CHM", 7, 6.0),
    ("cajamarca", "Cajamarca", -78.4, -7.1, "NAT", 3, 6.0),
    ("chachapoyas", "Chachapoyas", -77.8, -6.0, "NAT", 3, 6.0),
    ("huanuco", "Huánuco", -76.2, -9.8, "NAT", 2, 6.0),
    ("pachacamac", "Pachacámac", -77.0, -12.0, "NAT", 4, 6.0),
    ("jauja", "Xauxa", -75.4, -11.9, "NAT", 3, 6.0),
    ("chincha", "Chincha", -76.0, -13.6, "NAT", 4, 6.0),
    ("nazca", "Nazca", -74.9, -14.9, "NAT", 2, 6.0),
    # the Inca and the Altiplano
    ("cusco", "Cusco", -72.0, -13.5, "INC", 8, 6.0),
    ("apurimac", "Andahuaylas", -73.4, -13.7, "INC", 4, 6.0),
    ("antisuyu", "Antisuyu", -71.0, -12.0, "INC", 2, 6.0),
    ("arequipa", "Arequipa", -71.6, -16.3, "NAT", 3, 6.0),
    ("collao", "Hatun Colla", -70.2, -15.0, "CLL", 5, 6.0),
    ("chucuito", "Chucuito", -68.6, -16.9, "CLL", 4, 6.0),
    ("charcas", "Charcas", -65.6, -19.4, "NAT", 3, 6.0),
    ("atacama", "Atacama", -69.4, -22.0, "NAT", 1, 6.0),
    ("moxos", "Moxos", -65.0, -14.4, "NAT", 1, 6.0),
    ("chiquitos", "Chiquitos", -61.0, -17.4, "NAT", 1, 6.0),
    # Chile
    ("copiapo", "Copiapó", -70.2, -27.4, "NAT", 1, 6.0),
    ("coquimbo", "Coquimbo", -71.0, -30.2, "NAT", 2, 6.0),
    ("mapocho", "Mapocho", -70.7, -33.4, "NAT", 2, 6.0),
    ("maule", "Maule", -71.6, -35.6, "NAT", 2, 6.0),
    ("araucania", "Araucanía", -72.6, -38.6, "NAT", 3, 6.0),
    ("huilliche", "Huilliche", -73.2, -41.6, "NAT", 1, 6.0),
    ("aysen", "Chonos", -73.0, -46.4, "NAT", 1, 6.0),
    ("magallanes", "Feuerland", -69.8, -53.6, "NAT", 1, 6.0),
    # the Andes foothills, the Chaco and the Pampas
    ("tucuman", "Tucumán", -65.4, -26.6, "NAT", 2, 6.0),
    ("cuyo", "Cuyo", -68.6, -32.8, "NAT", 1, 6.0),
    ("cordoba", "Comechingones", -64.2, -31.4, "NAT", 1, 6.0),
    ("chaco", "Gran Chaco", -61.2, -24.4, "NAT", 1, 6.0),
    ("pampa", "Pampa", -62.4, -36.0, "NAT", 1, 6.0),
    ("rio_plata", "Río de la Plata", -58.6, -34.4, "NAT", 1, 6.0),
    ("parana", "Paraná", -59.6, -30.4, "NAT", 1, 6.0),
    ("patagonia", "Patagonien", -67.0, -42.6, "NAT", 1, 6.0),
    ("santa_cruz", "Santa Cruz", -69.6, -48.8, "NAT", 1, 6.0),
    ("malvinas", "Malwinen", -59.2, -51.7, "NAT", 1, 2.0),
    # Paraguay and the Banda Oriental
    ("guarani", "Guaraní", -57.6, -25.4, "NAT", 2, 6.0),
    ("charrua", "Charrúa", -56.0, -32.8, "NAT", 1, 6.0),
    ("guaira", "Guairá", -53.4, -24.6, "NAT", 1, 6.0),
    # the coast of Brazil
    ("tape", "Tape", -52.4, -29.6, "NAT", 1, 6.0),
    ("carijo", "Carijó", -49.2, -27.0, "NAT", 1, 6.0),
    ("sao_vicente", "São Vicente", -46.6, -23.6, "NAT", 2, 6.0),
    ("guanabara", "Guanabara", -43.2, -22.6, "NAT", 2, 6.0),
    ("espirito_santo", "Espírito Santo", -40.6, -19.8, "NAT", 1, 6.0),
    ("porto_seguro", "Porto Seguro", -39.4, -16.4, "NAT", 1, 6.0),
    ("bahia", "Bahia", -38.8, -12.8, "NAT", 2, 6.0),
    ("pernambuco", "Pernambuco", -35.4, -8.2, "NAT", 2, 6.0),
    ("potiguara", "Potiguara", -36.0, -5.6, "NAT", 1, 6.0),
    ("ceara", "Ceará", -39.2, -4.2, "NAT", 1, 6.0),
    ("maranhao", "Maranhão", -44.4, -3.0, "NAT", 1, 6.0),
    ("para", "Pará", -48.6, -1.6, "NAT", 1, 6.0),
    ("amapa", "Amapá", -51.4, 1.2, "NAT", 1, 6.0),
    # the interior of Brazil and the Amazon
    ("sertao", "Sertão", -41.0, -9.0, "NAT", 1, 6.0),
    ("tocantins", "Tocantins", -47.6, -8.6, "NAT", 1, 6.0),
    ("minas", "Minas", -44.4, -18.6, "NAT", 1, 6.0),
    ("goias", "Goiás", -49.6, -15.4, "NAT", 1, 6.0),
    ("mato_grosso", "Mato Grosso", -55.8, -13.6, "NAT", 1, 6.0),
    ("pantanal", "Pantanal", -56.8, -19.2, "NAT", 1, 6.0),
    ("tapajos", "Tapajós", -55.0, -4.4, "NAT", 1, 6.0),
    ("amazonas", "Amazonas", -60.4, -3.2, "NAT", 1, 6.0),
    ("madeira", "Madeira", -63.6, -8.6, "NAT", 1, 6.0),
    ("rio_negro", "Rio Negro", -66.0, 0.2, "NAT", 1, 6.0),
    ("solimoes", "Solimões", -68.4, -4.4, "NAT", 1, 6.0),
    ("maynas", "Maynas", -74.6, -3.8, "NAT", 1, 6.0),
    ("ucayali", "Ucayali", -73.8, -8.6, "NAT", 1, 6.0),
    # North America's west: north-west Mexico, Baja California, the south-west, the Great Basin, California,
    # the Pacific north-west and the plains below the Rockies up to the subarctic ("pac", also "nw")
    ("nayarit", "Nayarit", -104.9, 21.6, "NAT", 2),
    ("sinaloa", "Sinaloa", -107.4, 24.9, "NAT", 2),
    ("durango", "Tepehuanes", -104.9, 25.2, "NAT", 1, 4.0),
    ("conchos", "Conchos", -105.2, 27.8, "NAT", 1, 4.0),
    ("yaqui", "Yaqui", -109.6, 27.6, "NAT", 2),
    ("sonora", "Sonora", -110.6, 30.0, "NAT", 1, 4.0),
    ("chihuahua", "Paquimé", -107.4, 29.8, "NAT", 2, 4.0),
    ("baja_sur", "Pericú", -111.0, 25.4, "NAT", 1),
    ("baja_norte", "Cochimí", -114.6, 29.8, "NAT", 1),
    ("kumeyaay", "Kumeyaay", -116.6, 32.8, "NAT", 2),
    ("yuma", "Quechan", -114.4, 33.0, "NAT", 1, 4.0),
    ("tohono", "Tohono O'odham", -111.6, 32.2, "NAT", 2, 4.0),
    ("gila", "Gila", -108.8, 33.0, "NAT", 1, 4.0),
    ("pueblo", "Pueblo", -106.3, 35.4, "NAT", 3, 4.0),
    ("zuni", "Zuni", -108.7, 35.3, "NAT", 2, 4.0),
    ("hopi", "Hopi", -110.6, 35.8, "NAT", 2, 4.0),
    ("dine", "Diné", -108.6, 37.3, "NAT", 1, 4.0),
    ("mojave", "Mojave", -115.6, 35.2, "NAT", 1, 4.0),
    ("paiute", "Südliche Paiute", -112.8, 37.6, "NAT", 1, 4.0),
    ("ute", "Ute", -107.4, 39.6, "NAT", 1, 4.5),
    ("arapaho", "Arapaho", -104.6, 40.0, "NAT", 1, 4.5),
    ("timpanogos", "Timpanogos", -111.8, 40.6, "NAT", 1, 4.0),
    ("great_basin", "Westliche Shoshone", -116.6, 39.4, "NAT", 1, 4.5),
    ("wind_river", "Shoshone", -108.4, 43.2, "NAT", 1, 4.5),
    ("crow", "Absaroka", -107.6, 46.0, "NAT", 1, 4.5),
    ("blackfoot", "Blackfoot", -112.4, 48.2, "NAT", 1, 4.5),
    ("snake", "Snake River", -114.6, 43.4, "NAT", 1, 4.5),
    ("nez_perce", "Nez Percé", -116.4, 46.2, "NAT", 1, 4.0),
    ("chumash", "Chumash", -119.8, 34.6, "NAT", 3),
    ("tongva", "Tongva", -117.9, 34.0, "NAT", 2),
    ("yokuts", "Yokuts", -119.6, 36.6, "NAT", 2),
    ("ohlone", "Ohlone", -122.0, 37.4, "NAT", 2),
    ("pomo", "Pomo", -122.9, 39.0, "NAT", 2),
    ("maidu", "Maidu", -121.0, 39.8, "NAT", 2),
    ("yurok", "Yurok", -123.8, 41.2, "NAT", 2),
    ("klamath", "Klamath", -121.6, 42.6, "NAT", 1),
    ("n_paiute", "Nördliche Paiute", -119.0, 43.6, "NAT", 1, 4.5),
    ("kalapuya", "Kalapuya", -123.0, 44.6, "NAT", 1),
    ("chinook", "Chinook", -123.6, 46.4, "NAT", 2),
    ("yakama", "Yakama", -120.4, 46.8, "NAT", 1),
    ("salish", "Küsten-Salish", -122.4, 47.8, "NAT", 2),
    ("nuu_chah_nulth", "Nuu-chah-nulth", -125.6, 49.6, "NAT", 1),
    ("secwepemc", "Secwepemc", -120.2, 50.8, "NAT", 1, 4.5),
    ("ktunaxa", "Ktunaxa", -116.2, 49.8, "NAT", 1, 4.5),
    ("dakelh", "Dakelh", -123.6, 54.0, "NAT", 1, 5.0),
    ("cree_plains", "Plains Cree", -112.6, 53.4, "NAT", 1, 5.0),
    ("athabasca", "Athabasca", -114.0, 58.6, "NAT", 1, 6.0),
    ("sekani", "Sekani", -124.0, 58.4, "NAT", 1, 6.0),
    # the Low Countries: Holland's neighbours for the Netherlands (Old World again, after every overseas block)
    ("zeeland", "Zeeland", 3.8, 51.5, "NED", 6),
    ("utrecht", "Utrecht", 5.4, 52.0, "NED", 7),
    ("friesland", "Friesland", 5.9, 53.1, "NED", 5),
]

# Extra sea/strait connections (province keys)
STRAITS = [
    ("london", "calais"), ("wessex", "normandy"), ("pale", "wales"),
    ("ulster", "lothian"), ("corsica", "genoa"), ("corsica", "sardinia"),
    ("sicily", "calabria"), ("copenhagen", "scania"), ("copenhagen", "jutland"),
    ("stockholm", "turku"), ("turku", "reval"),
    ("cornwall", "brest"), ("sardinia", "barcelona"), ("sicily", "napoli"),
    ("dalmatia", "ancona"),
    ("constantinople", "izmit"), ("edirne", "bursa"), ("crimea", "circassia"), ("sevilla", "tangier"),
    ("granada", "tangier"), ("sicily", "tunis"), ("sardinia", "tunis"), ("crete", "morea"),
    ("crete", "rhodes"), ("rhodes", "mentese"), ("cyprus", "icel"), ("cyprus", "tripoli_sy"),
    # the New World
    ("havana", "florida"), ("havana", "yucatan"), ("oriente", "ayiti"), ("oriente", "jamaica"),
    ("quisqueya", "boriken"), ("boriken", "antilles"), ("antilles", "trinidad"), ("lucayas", "florida"),
    ("lucayas", "camaguey"), ("newfoundland", "labrador"), ("newfoundland", "mikmaq"),
    # the Red Sea, the Gulf of Aden and the Persian Gulf
    ("aden", "zeila"), ("tihama", "danakil"), ("mecca", "suakin"), ("hasa", "bushehr"),
    # Zanzibar and the Mozambique Channel (Comoros crossing)
    ("zanzibar", "kilwa"), ("zanzibar", "mombasa"), ("mozambique", "boina"),
    # South America: Trinidad, Tierra del Fuego, the Falklands; the Panama isthmus is a land link below
    ("trinidad", "cumana"), ("magallanes", "santa_cruz"), ("malvinas", "santa_cruz"),
    # Vancouver Island (Strait of Georgia, Juan de Fuca)
    ("nuu_chah_nulth", "salish"), ("nuu_chah_nulth", "secwepemc"),
]

# land borders the coarse polygons miss (isthmus, small gaps): adjacency only, not sea crossings
LAND_LINKS = [("constantinople", "edirne"), ("morea", "thessaly"), ("crimea", "zaporozhia"),
              # caravan routes across the Sahara (slow: long march distance)
              ("sous", "taghaza"), ("taghaza", "timbuktu"), ("taghaza", "walata"),
              # the Hejaz road and the Nile (desert gaps the radius clip leaves open)
              ("tabuk", "medina"), ("basra", "hasa"), ("aswan", "upper_egypt"), ("aswan", "dongola"), ("dongola", "alwa"),
              # Saharan caravans to the Fezzan and Lake Chad, and the Nile into the Sudd
              ("fezzan", "tripoli"), ("fezzan", "sirte"), ("fezzan", "kanem"), ("fezzan", "air"), ("tibesti", "kanem"),
              ("sudd", "sennar"),
              # the Darién gap (the coarse polygons leave the isthmus open)
              ("darien", "zenu")]

sys.path.insert(0, os.path.dirname(__file__))
import world  # noqa: E402  (the regions appended after the Low Countries: tools/world/)
PROVINCES = PROVINCES + world.provinces()
for _r in world.REGIONS:
    STRAITS += _r.STRAITS
    LAND_LINKS += _r.LAND_LINKS
from mapproj import SCALE, proj, size, windows  # noqa: E402

FIRST_NEW_WORLD = "tenochtitlan"  # provinces from here on are overseas/colonial ("nw" in map.json)
FIRST_AFRICA = "arguin"  # ... and from here on they are West Africa ("wa" in map.json, also "nw")
FIRST_EAST = "baghdad"  # ... up to here: the Middle East and the Horn are Old World again ("east" in map.json)
FIRST_SOUTH = "fezzan"  # ... and from here on Africa south of the Sahara: overseas again ("af", also "nw" and "wa")
FIRST_SA = "calusa"  # ... and from here on South America and the finer east coast of North America ("sa", also "nw")
FIRST_PAC = "nayarit"  # ... then the North American west ("pac", also "nw"; region "america")
FIRST_LOW = "zeeland"  # ... and the Low Countries: Old World again (no flag)
# big African lakes cut out of the land south of the Sahara
AF_LAKES = {"Lake Victoria", "Lake Tanganyika", "Lake Malawi", "Lake Baikal", "Lake Balkhash", "Issyk-Kul"}
# the Aral Sea of the 15th century (Natural Earth has today's remnant)
ARAL = [(58.2, 45.0), (58.6, 44.0), (59.5, 43.5), (60.6, 43.6), (61.3, 44.3), (61.7, 45.3), (61.4, 46.2), (60.8, 46.8), (59.8, 46.8),
        (59.0, 46.3), (58.3, 45.8)]
# the painted map is cut into square tiles (Android caps textures at 4096 px); a tile is only painted if
# land lies within TILE_MARGIN px of it, the rest of the sea is the plain deep-sea colour
TILE = 2048
TILE_MARGIN = 256
# big lakes cut out of the New World land (Natural Earth lakes); Europe keeps its old shapes
LAKES = {"Lake Superior", "Lake Michigan", "Lake Huron", "Lake Erie", "Lake Ontario", "Lake Winnipeg", "Lago de Nicaragua", "Lago Titicaca"}


def project_geom(g):
    import shapely
    return shapely.transform(g, lambda c: [proj(x, y) for x, y in c])


def parts_of(g):
    if g.geom_type == "Polygon":
        return [g]
    return [q for q in getattr(g, "geoms", []) if q.geom_type == "Polygon"]


def main(land_path, lakes_path):
    with open(land_path) as f:
        gj = json.load(f)
    with open(lakes_path) as f:
        lakes_gj = json.load(f)
    lakes = unary_union([shape(ft["geometry"]) for ft in lakes_gj["features"] if ft["properties"].get("name") in LAKES])
    af_lakes = unary_union([shape(ft["geometry"]) for ft in lakes_gj["features"] if ft["properties"].get("name") in AF_LAKES] + [Polygon(ARAL)])
    land_parts = []
    for feat in gj["features"]:
        g = shape(feat["geometry"])
        for wi, window in enumerate(windows()):
            if g.intersects(window):
                part = g.intersection(window)
                if wi == 1:
                    part = part.difference(lakes)
                else:
                    part = part.difference(af_lakes)
                land_parts.append(project_geom(part))
    # Natural Earth cuts the Suez Canal (1869) through the isthmus: close it again
    land_parts.append(project_geom(box(32.1, 29.94, 32.7, 31.32)))
    land = unary_union(land_parts).buffer(0)
    full_land = land

    pts = [proj(p[2], p[3]) for p in PROVINCES]
    W, H = size()
    vor = voronoi_polygons(MultiPoint(pts), extend_to=box(-500, -500, W + 500, H + 500))
    cells_by_idx = {}
    for cell in vor.geoms:
        for i, pt in enumerate(pts):
            if cell.contains(Point(pt)):
                cells_by_idx[i] = cell
                break

    nw_first = next(i for i, p in enumerate(PROVINCES) if p[0] == FIRST_NEW_WORLD)
    wa_first = next(i for i, p in enumerate(PROVINCES) if p[0] == FIRST_AFRICA)
    east_first = next(i for i, p in enumerate(PROVINCES) if p[0] == FIRST_EAST)
    south_first = next(i for i, p in enumerate(PROVINCES) if p[0] == FIRST_SOUTH)
    sa_first = next(i for i, p in enumerate(PROVINCES) if p[0] == FIRST_SA)
    pac_first = next(i for i, p in enumerate(PROVINCES) if p[0] == FIRST_PAC)
    low_first = next(i for i, p in enumerate(PROVINCES) if p[0] == FIRST_LOW)
    max_r = 3.2 * SCALE
    raw = []
    for i, p in enumerate(PROVINCES):
        cell = cells_by_idx[i]
        disc = Point(pts[i]).buffer(p[6] * SCALE if len(p) > 6 else max_r, 24)
        g = cell.intersection(disc).intersection(land)
        polys = [q for q in parts_of(g) if q.area > 25.0]
        if not polys:
            raise SystemExit("empty province " + p[0])
        raw.append(polys)
    # A Voronoi cell reaches across water and can grab a strip of another coast (Kintyre went to Ulster,
    # the heel of Apulia to Albania, the Finnish coast to Reval). Each province keeps its main part (the
    # one holding its centre, else the largest); every other part goes to the province it touches
    # (longest shared border) or, if it touches none, to the nearest main part (islands).
    main_parts = []
    frags = []
    for i, polys in enumerate(raw):
        c = Point(pts[i])
        big = max(polys, key=lambda q: q.area)
        mp = next((q for q in polys if q.buffer(0.5).contains(c)), None) or big
        if mp.area < 0.25 * big.area:  # centre on a small island (Montreal): the mainland part counts
            mp = big
        main_parts.append(mp)
        frags += [(i, q) for q in polys if q is not mp]
    groups = [[mp] for mp in main_parts]
    frags.sort(key=lambda f: -f[1].area)
    moved = 0
    for owner, q in frags:
        cur = [unary_union(gs) for gs in groups]
        best, best_len = -1, 0.0
        for j, s in enumerate(cur):
            if s.distance(q) < 1.0:
                ln = q.buffer(1.0).intersection(s.buffer(1.0)).area
                if ln > best_len:
                    best, best_len = j, ln
        if best < 0:
            best = min(range(len(cur)), key=lambda j: main_parts[j].distance(q))
        if best != owner:
            moved += 1
            if os.environ.get("GEN_MAP_VERBOSE"):
                print("  fragment %s -> %s (%.0f px²)" % (PROVINCES[owner][0], PROVINCES[best][0], q.area))
        groups[best].append(q)
    print("moved fragments:", moved)
    provinces = []
    shapes = []
    for i, p in enumerate(PROVINCES):
        g = unary_union(groups[i]).simplify(1.2, preserve_topology=True)
        polys = [q for q in parts_of(g) if q.area > 25.0]
        shapes.append(unary_union(polys))
        d = {
            "id": i,
            "key": p[0],
            "name": p[1],
            "owner": p[4],
            "dev": p[5],
            "center": [round(pts[i][0], 1), round(pts[i][1], 1)],
            "polys": [[[round(x, 1), round(y, 1)] for x, y in list(q.exterior.coords)[:-1]] for q in polys],
        }
        if east_first > i >= nw_first:
            d["nw"] = True
        if east_first > i >= wa_first:
            d["wa"] = True
        if south_first > i >= east_first:
            d["east"] = True
        if sa_first > i >= south_first:
            d["nw"] = True
            d["wa"] = True
            d["af"] = True
        if pac_first > i >= sa_first:
            d["nw"] = True
            d["sa"] = True
        if low_first > i >= pac_first:
            d["nw"] = True
            d["pac"] = True
        r = world.region_of(p[0]) if i >= low_first else None
        if r is not None:
            d[r.BLOCK] = True
            d.update(r.FLAGS)
            if p[0] in getattr(r, "RELIGION", {}):
                d["religion"] = r.RELIGION[p[0]]  # the people's faith, when it is not the ruler's
        provinces.append(d)

    key_to_id = {p[0]: i for i, p in enumerate(PROVINCES)}
    if len(key_to_id) != len(PROVINCES):
        dup = sorted({p[0] for p in PROVINCES if sum(1 for q in PROVINCES if q[0] == p[0]) > 1})
        raise SystemExit("duplicate province keys: %s" % dup)
    adj = [set() for _ in PROVINCES]
    tree = STRtree(shapes)
    for i in range(len(shapes)):
        for j in tree.query(shapes[i].buffer(1.5)):
            j = int(j)
            if j <= i:
                continue
            if shapes[i].distance(shapes[j]) < 1.5:
                inter = shapes[i].buffer(1.0).intersection(shapes[j].buffer(1.0))
                if inter.area > 6.0:
                    adj[i].add(j)
                    adj[j].add(i)
    for a, b in STRAITS + LAND_LINKS:
        ia, ib = key_to_id[a], key_to_id[b]
        adj[ia].add(ib)
        adj[ib].add(ia)
    for i, p in enumerate(provinces):
        p["adj"] = sorted(adj[i])
        if not p["adj"]:
            raise SystemExit("isolated province " + p["key"])

    # background land (no province) for geography context
    covered = unary_union(shapes).buffer(0.5)
    rest = full_land.difference(covered).simplify(2.0, preserve_topology=True)
    bg = []
    for q in getattr(rest, "geoms", [rest]):
        if q.geom_type == "Polygon" and q.area > 200.0:
            bg.append([[round(x, 1), round(y, 1)] for x, y in list(q.exterior.coords)[:-1]])

    # [file, x, y, w, h] in map pixels: the grid cells with land nearby
    tiles = []
    for row in range(0, H, TILE):
        for col in range(0, W, TILE):
            cell = box(col - TILE_MARGIN, row - TILE_MARGIN, col + TILE + TILE_MARGIN, row + TILE + TILE_MARGIN)
            if full_land.intersects(cell):
                tiles.append(["terrain_%d_%d.png" % (col // TILE, row // TILE), col, row, min(TILE, W - col), min(TILE, H - row)])
    out = {"size": [W, H], "terrain_tiles": tiles, "provinces": provinces, "background": bg}
    with open("data/map.json", "w") as f:
        json.dump(out, f, separators=(",", ":"), ensure_ascii=False)
    # sea crossings: slower marches, need sea control in war (scripts/core/warfare.gd)
    with open("data/straits.json", "w") as f:
        f.write("[\n" + ",\n".join(json.dumps([a, b]) for a, b in STRAITS) + "\n]\n")
    print(len(provinces), "provinces, bg polys:", len(bg), "size", out["size"])


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
