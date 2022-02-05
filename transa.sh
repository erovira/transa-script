#!/bin/sh

# TODO: Simplify this.
BUYSELL_LINES=$(
    curl --silent https://www.itau.com.uy/inst/aci/cotiz.xml | \
    grep 'LINK' --after-context=2 | \
    # Long form of -n is not the same in linux/mac
    tail -n 2 | \
    grep --only-match '[[:digit:]]\{2\}[,][[:digit:]]\{2\}' | \
    tr "," "." | \
    tr "\n" " " | \
    grep --only-match --extended-regexp "[0-9.]+"
)

BUY=$(echo "$BUYSELL_LINES" | head -n 1)
SELL=$(echo "$BUYSELL_LINES" | tail -n 1)

MEAN_EXPR="(${BUY} + ${SELL}) / 2"

# --mathlib is for bc to use decimals properly
MEAN=$(echo "${MEAN_EXPR}" | bc --mathlib)

echo "Itaú compra y venta: ${BUY}, ${SELL}"

# Echo mean computation, in case anyone wants to replicate it themselves.
echo "${MEAN_EXPR} = ${MEAN}"

# Thanks SO
beginswith() { case "$2" in "$1"*) true;; *) false;; esac; }

if [ -n "$1" ]
then
    if beginswith "$" "$1"; then
        UYU=$(echo "$1" | cut -c 2-) # Drop the initial `$` from the input.
        USD=$(echo "scale=2; (${UYU} / ${MEAN})" | bc --mathlib)
    else
        USD=$(printf %.2f "$1")
        UYU=$(printf %.2f "$(echo "(${USD} * ${MEAN})" | bc --mathlib)")
    fi
    echo "TRANSA: U\$S $USD = $ $UYU"
fi
