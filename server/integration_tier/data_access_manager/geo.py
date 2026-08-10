"""! @file geo.py
@brief Primitive geospaziali pure-Python per Firestore (geohash, bbox, point-in-polygon).

Firestore non ha query spaziali native (§10.4): la prossimità si risolve con un
campo `geohash` sul documento + filtro bounding-box, e il geofencing con il
point-in-polygon calcolato lato server. Questo modulo implementa tutto in Python
puro (nessuna dipendenza esterna: niente Shapely/GeoPy da approvare, §3),
sufficiente alla scala cittadina del progetto.

@note Coordinate sempre in gradi decimali WGS84 (lat in [-90,90], lon in [-180,180]).
"""

from __future__ import annotations

import math

#! Alfabeto base32 dello standard geohash (Gustavo Niemeyer).
_BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"
#! Raggio medio terrestre in metri (per la formula dell'emisenoverso).
_RAGGIO_TERRA_M = 6_371_000.0


def geohash(lat: float, lon: float, precisione: int = 9) -> str:
    """! @brief Codifica una coordinata in geohash base32.

    Biseziona alternativamente l'intervallo di longitudine e latitudine,
    accumulando i bit nel carattere base32 corrente (standard geohash).

    @param lat Latitudine in gradi decimali (WGS84).
    @param lon Longitudine in gradi decimali (WGS84).
    @param precisione Numero di caratteri del geohash (1-12; default 9 ≈ ±2,4 m).
    @return Stringa geohash di lunghezza @p precisione.
    @throws ValueError Se la precisione non è compresa tra 1 e 12.
    """
    if not 1 <= precisione <= 12:
        raise ValueError("La precisione del geohash deve essere tra 1 e 12")
    lat_min, lat_max = -90.0, 90.0
    lon_min, lon_max = -180.0, 180.0
    hash_caratteri: list[str] = []
    bit = 0
    valore = 0
    pari = True  # si parte bisezionando la longitudine
    while len(hash_caratteri) < precisione:
        if pari:
            meta = (lon_min + lon_max) / 2
            if lon >= meta:
                valore = (valore << 1) | 1
                lon_min = meta
            else:
                valore = valore << 1
                lon_max = meta
        else:
            meta = (lat_min + lat_max) / 2
            if lat >= meta:
                valore = (valore << 1) | 1
                lat_min = meta
            else:
                valore = valore << 1
                lat_max = meta
        pari = not pari
        bit += 1
        if bit == 5:
            hash_caratteri.append(_BASE32[valore])
            bit = 0
            valore = 0
    return "".join(hash_caratteri)


def riquadro(lat: float, lon: float, raggio_m: float) -> tuple[float, float, float, float]:
    """! @brief Calcola il bounding-box (riquadro) attorno a un centro dato un raggio.

    Approssimazione equirettangolare adatta alla scala cittadina: 1° di latitudine
    ≈ 111,32 km; i gradi di longitudine sono scalati per il coseno della latitudine.

    @param lat Latitudine del centro (gradi decimali).
    @param lon Longitudine del centro (gradi decimali).
    @param raggio_m Raggio di ricerca in metri (>= 0).
    @return Tupla (lat_min, lat_max, lon_min, lon_max) del riquadro.
    """
    raggio_m = max(0.0, raggio_m)
    delta_lat = raggio_m / 111_320.0
    coseno = max(0.000001, math.cos(math.radians(lat)))
    delta_lon = raggio_m / (111_320.0 * coseno)
    return (lat - delta_lat, lat + delta_lat, lon - delta_lon, lon + delta_lon)


def distanza_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """! @brief Distanza geodetica tra due punti (formula dell'emisenoverso/haversine).
    @param lat1 Latitudine del primo punto (gradi decimali).
    @param lon1 Longitudine del primo punto (gradi decimali).
    @param lat2 Latitudine del secondo punto (gradi decimali).
    @param lon2 Longitudine del secondo punto (gradi decimali).
    @return Distanza in metri lungo la superficie terrestre.
    """
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    return 2 * _RAGGIO_TERRA_M * math.asin(math.sqrt(a))


def punto_in_poligono(lat: float, lon: float, poligono: list[tuple[float, float]]) -> bool:
    """! @brief Verifica se un punto è interno a un poligono (algoritmo ray-casting).

    Conta le intersezioni di una semiretta orizzontale uscente dal punto con i lati
    del poligono: numero dispari ⇒ interno. Usato per il geofencing (AP.06/AP.08/OP.04):
    aree di interdizione, slow-zone, aree operative (§10.4).

    @param lat Latitudine del punto da testare (gradi decimali).
    @param lon Longitudine del punto da testare (gradi decimali).
    @param poligono Vertici del poligono come lista di (lat, lon); il perimetro si
                    chiude automaticamente (ultimo vertice → primo).
    @return True se il punto è interno al poligono, False altrimenti.
    """
    n = len(poligono)
    if n < 3:
        return False
    dentro = False
    j = n - 1
    for i in range(n):
        lat_i, lon_i = poligono[i]
        lat_j, lon_j = poligono[j]
        interseca = (lon_i > lon) != (lon_j > lon)
        if interseca:
            lat_taglio = (lat_j - lat_i) * (lon - lon_i) / (lon_j - lon_i) + lat_i
            if lat < lat_taglio:
                dentro = not dentro
        j = i
    return dentro
