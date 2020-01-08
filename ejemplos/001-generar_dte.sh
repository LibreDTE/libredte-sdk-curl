#
# LibreDTE
# Copyright (C) SASCO SpA (https://sasco.cl)
#
# Este programa es software libre: usted puede redistribuirlo y/o modificarlo
# bajo los términos de la GNU Lesser General Public License (LGPL) publicada
# por la Fundación para el Software Libre, ya sea la versión 3 de la Licencia,
# o (a su elección) cualquier versión posterior de la misma.
#
# Este programa se distribuye con la esperanza de que sea útil, pero SIN
# GARANTÍA ALGUNA; ni siquiera la garantía implícita MERCANTIL o de APTITUD
# PARA UN PROPÓSITO DETERMINADO. Consulte los detalles de la GNU Lesser General
# Public License (LGPL) para obtener una información más detallada.
#
# Debería haber recibido una copia de la GNU Lesser General Public License
# (LGPL) junto a este programa. En caso contrario, consulte
# <http://www.gnu.org/licenses/lgpl.html>.
#

#
# Este código requiere: curl y jq
#

# datos para autenticación en LibreDTE
LIBREDTE_APP_URL="https://libredte.cl"
LIBREDTE_APP_API_KEY=""

# documento que se desea generar
DTE='{
    "Encabezado" : {
        "IdDoc" : {
            "TipoDTE" : 33
        },
        "Emisor" : {
            "RUTEmisor" : "76192083-9"
        },
        "Receptor" : {
            "RUTRecep" : "66666666-6",
            "RznSocRecep" : "Persona sin RUT",
            "GiroRecep" : "Particular",
            "DirRecep" : "Santiago",
            "CmnaRecep" : "Santiago"
        }
    },
    "Detalle" : [
        {
            "NmbItem" : "Producto 1",
            "QtyItem" : 2,
            "PrcItem" : 1000
        }
    ]
}'

# crear DTE temporal
STATUS=$(
    curl --location --request POST "$LIBREDTE_APP_URL/api/dte/documentos/emitir" \
        --header "Accept: application/json" \
        --header "Content-Type: application/json" \
        --header "Authorization: $LIBREDTE_APP_API_KEY" \
        --silent \
        --output temporal.json \
        --write-out "%{http_code}\n" \
        --data "$DTE"
)
if [ $STATUS -ne 200 ]; then
    echo "Error: `cat temporal.json`"
    exit
fi

# crear DTE real
STATUS=$(
    curl --location --request POST "$LIBREDTE_APP_URL/api/dte/documentos/generar" \
        --header "Accept: application/json" \
        --header "Content-Type: application/json" \
        --header "Authorization: $LIBREDTE_APP_API_KEY" \
        --silent \
        --output emitido.json \
        --write-out "%{http_code}\n" \
        --data "`cat temporal.json`"
)
if [ $STATUS -ne 200 ]; then
    echo "Error: `cat emitido.json`"
    exit
fi

# obtener código dte, folio y emisor desde el DTE real generado
EMITIDO_EMISOR=$(jq '.emisor' emitido.json)
EMITIDO_DTE=$(jq '.dte' emitido.json)
EMITIDO_FOLIO=$(jq '.folio' emitido.json)

# obtener el PDF del DTE
STATUS=$(
    curl --location --request GET "$LIBREDTE_APP_URL/api/dte/dte_emitidos/pdf/$EMITIDO_DTE/$EMITIDO_FOLIO/$EMITIDO_EMISOR" \
        --header "Accept: application/json" \
        --header "Accept: application/pdf" \
        --header "Authorization: $LIBREDTE_APP_API_KEY" \
        --silent \
        --output emitido.pdf \
        --write-out "%{http_code}\n" \
)
if [ $STATUS -ne 200 ]; then
    echo "Error: `cat emitido.pdf`"
    exit
fi
