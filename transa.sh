#!/bin/sh

BUYSELL=$(
    curl --silent https://www.itau.com.uy/inst/aci/cotiz.xml | \
    grep 'LINK' --after-context=2 | \
    # Long form of -n is not the same in linux/mac
    tail -n 2 | \
    grep --only-match '[[:digit:]]\{2\}[,][[:digit:]]\{2\}' | \
    tr "," "." | \
    tr "\n" " "
)

# A (probably super) dumb way of extracting buy/sale prices
BUY=$(echo $BUYSELL | grep --only-match --extended-regexp "[0-9.]+ " | tr -d " ")
SELL=$(echo $BUYSELL | grep --only-match --extended-regexp " [0-9.]+" | tr -d " ")

MEAN_EXPR="(${BUY} + ${SELL}) / 2"

# --mathlib is for bc to use decimals properly
# scale=2 is for bc to restrict results to 2 decimal digits.
MEAN=$(echo "scale=2; ${MEAN_EXPR}" | bc --mathlib)

echo "Itaú compra y venta: ${BUY}, ${SELL}"

# Echo mean computation, in case anyone wants to replicate it themselves.
echo "${MEAN_EXPR} = ${MEAN}"

if [ -n "$1" ]
then
    PESOS=$(echo "scale=2; ($1 * ${MEAN})" | bc --mathlib)
    echo "TRANSA: U\$S $1 = $ $PESOS"
fi
