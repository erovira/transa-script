#!/bin/bash

# Make the shell script more safe
# - errexit: Stops execution whenever a command fails.
# - noglob: Disable globbing.
# - nounset: Treat unset variables as an error and exit immediately.
set -o errexit -o noglob -o nounset

DEFAULT="itau"

exit_instructions() {
    echo "Correct usage examples:"
    echo "  transa"
    echo "  transa <amount>"
    echo "  transa <amount> brou"
    echo "  transa <amount> itau"
    echo "  transa itau"
    echo "  transa brou"
    echo ""
    echo "If using amount with \$, make sure to escape it:"
    echo "  transa \\\$20000'"
    echo "  transa \\\$20000' brou"
    exit 1
}

# Act depending on the number of arguments
if [ $# -eq 0 ]; then
    AMOUNT=""
    EXCHANGE=$DEFAULT
elif [ $# -eq 1 ]; then
    # transa <number> or transa brou
    if [[ $1 =~ ^[$]?[0-9]*\.?[0-9]+$ ]]; then
        AMOUNT=$1
        EXCHANGE=$DEFAULT
    else
        AMOUNT=""
        EXCHANGE=$1
    fi
elif [ $# -eq 2 ]; then
    AMOUNT=$1
    EXCHANGE=$2
else
    exit_instructions
fi

# Default to "itau" and convert to lowercase
EXCHANGE=$(echo "$EXCHANGE" | tr '[:upper:]' '[:lower:]')

if [[ $EXCHANGE == "brou" ]]; then
    EXCHANGE_NAME="eBROU"
    html_contents=$(wget -qO- 'https://www.brou.com.uy/c/portal/render_portlet?p_l_id=20593&p_p_id=cotizacionfull_WAR_broutmfportlet_INSTANCE_otHfewh1klyS&p_p_lifecycle=0&p_t_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_pos=0&p_p_col_count=2&p_p_isolated=1&currentURL=%2Fweb%2Fguest%2Fcotizaciones')
    RATES=$(echo "$html_contents" | xmllint --html --xpath "//p[text()='DÃ³lar eBROU']/../../..//p[@class='valor']/text()" - | tr ',' '.' | tr '\n' ' ')
    BUY=$(echo "$RATES" | awk '{print $1}')
    SELL=$(echo "$RATES" | awk '{print $2}')
elif [[ $EXCHANGE == "itau" ]]; then
    EXCHANGE_NAME="Itaú"
    xml_contents=$(wget -qO- https://www.itau.com.uy/inst/aci/cotiz.xml)
    BUY=$(echo "$xml_contents" | xmllint --xpath "//cotizacion[moneda='LINK']/compra/text()" - | tr ',' '.')
    SELL=$(echo "$xml_contents" | xmllint --xpath "//cotizacion[moneda='LINK']/venta/text()" - | tr ',' '.')
else
    exit_instructions
fi

echo "$EXCHANGE_NAME compra y venta: ${BUY}, ${SELL}"

#
# Compute the median
#
MEAN_EXPR="(${BUY} + ${SELL}) / 2"

# --mathlib is for bc to use decimals properly
CALC="bc --mathlib"
MEAN=$(echo "${MEAN_EXPR}" | $CALC)

# Echo mean computation, in case anyone wants to replicate it themselves.
echo "${MEAN_EXPR} = ${MEAN}"

# Thanks SO
beginswith() { case "$2" in "$1"*) true ;; *) false ;; esac }

# Use GNU's printf instead of bash builtin
ROUND_TWO="/usr/bin/printf %.2f"

if [[ -n "$AMOUNT" ]]; then
    # `printf %.2f` rounds the input to two decimal places.

    if beginswith "$" "$AMOUNT"; then
        # The `cut` command drops the initial `$` from the input.
        UYU=$(echo "$($ROUND_TWO "$(echo "$AMOUNT" | cut -c 2-)")" | tr ',' '.')
        # echo "UYU ES $UYU"
        USD=$($ROUND_TWO "$(echo "(${UYU} / ${MEAN})" | $CALC)")
    else
        USD=$(echo $($ROUND_TWO "$AMOUNT") | tr ',' '.')
        UYU=$($ROUND_TWO "$(echo "(${USD} * ${MEAN})" | $CALC)") # This fails with bash's builtin printf
    fi

    if [ "$USD" != "0.00" ]; then
        echo ""
        echo "TRANSA: U\$S $USD = $ $UYU"
    fi
fi
