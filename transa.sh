#!/bin/sh

# Make the shell script more safe
# - errexit: Stops execution whenever a command fails.
# - noglob: Disable globbing.
# - nounset: Treat unset variables as an error and exit immediately.
set -o errexit -o noglob -o nounset

# So that printf uses dot for de decimal separator and no thousands' grouping
# regardless of the user's locale.
LC_NUMERIC="POSIX"

DEFAULT="itau"

exit_instructions() {
    >&2 echo "General usage:"
    >&2 echo "  ${0} [<amount>] [itau|brou|bcu] [-j|--json]"
    >&2 echo ""
    >&2 echo "Usage examples:"
    >&2 echo "  ${0}"
    >&2 echo "  ${0} <amount>"
    >&2 echo "  ${0} <amount> brou"
    >&2 echo "  ${0} <amount> itau"
    >&2 echo "  ${0} <amount> bcu"
    >&2 echo "  ${0} itau"
    >&2 echo "  ${0} brou"
    >&2 echo "  ${0} bcu"
    >&2 echo ""
    >&2 echo "If using amount with \$, make sure to escape it:"
    >&2 echo "  ${0} \\\$20000"
    >&2 echo "  ${0} \\\$20000 brou"
}

seven_days_ago() {
    # -o/--operating-system to avoid printing other system info.
    os=$(uname -o | tr '[:upper:]' '[:lower:]')
    if [ "$os" = "darwin" ]; then
        date -v-7d +%d/%m/%Y
    else
        date -d "7 days ago" +%d/%m/%Y
    fi
}

# region New argument processing

json_flag=false
position=0

arg1=""
arg2=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        # Flags
        -j|--json)
            json_flag=true
            shift
            ;;
        *)
            # Positionals
            case "$position" in
                0)
                    # Position was initialized at 0, so we store the first positional in `arg1` and increment `position`.
                    position=1
                    arg1=$1
                    shift
                    ;;
                1)
                    # If we're here it means we've already consumed one positional and we're about to consume the second one.
                    position=2
                    arg2=$1
                    shift
                    ;;
                2)
                    # We only expected two positionals. If we're here it means we've received more. We need to exit with an error.
                    /usr/bin/printf "%b\n" "Unknown positional: $1\n" >&2
                    exit_instructions
                    exit 1
            esac
    esac
done

# endregion

if [ "$arg1" = "" ]; then
    # If arg1 is empty, then arg2 must be empty by construction, therefore we're in the case of:
    # - No amount provided, so we'll only fetch exchange rates.
    # - Use default exchange: itau
    AMOUNT=""
    EXCHANGE=$DEFAULT
elif [ "$arg2" = "" ]; then
    # Only one positional argument was passed, we need to determine if it's an amount or an exchange.
    if echo "$arg1" | grep -E -q '^[$]?[[:digit:]]*\.?[[:digit:]]+$'; then
        # In this case it's an amount.
        AMOUNT=$arg1
        EXCHANGE=$DEFAULT
    else
        # In this case, we ASSUME it was an exchange. We'll check if it's valid below.
        AMOUNT=""
        EXCHANGE=$arg1
    fi
else
    AMOUNT=$arg1
    EXCHANGE=$arg2
fi

# Default to "itau" and convert to lowercase
EXCHANGE=$(echo "$EXCHANGE" | tr '[:upper:]' '[:lower:]')

# Use GNU's printf instead of bash builtin
# `printf %.2f` rounds the input to two decimal places.
ROUND_TWO="/usr/bin/printf %.2f"

# macOS doesn't ship with `wget` by default, but does with `curl` which is why it's our first option.
if command -v curl > /dev/null
then
    FETCH="curl --silent"
    FETCH_POST() {
        curl --insecure --silent --header "Content-Type: application/json" --request POST --data "$1" "$2"
    }
elif command -v wget > /dev/null
then
    FETCH="wget --quiet --output-document=/dev/stdout"
    FETCH_POST() {
        wget --no-check-certificate --quiet --method POST --header='Content-Type: application/json' --body-data="$1" --output-document=/dev/stdout "$2"
    }
else
    >&2 echo "ERROR: Unable to fetch exchange rates. Please make sure either \"curl\" or \"wget\" are installed."
    exit 1
fi


if [ "$EXCHANGE" = "brou" ]; then
    EXCHANGE_NAME="eBROU"
    html_contents=$($FETCH 'https://www.brou.com.uy/c/portal/render_portlet?p_l_id=20593&p_p_id=cotizacionfull_WAR_broutmfportlet_INSTANCE_otHfewh1klyS&p_p_lifecycle=0&p_t_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_pos=0&p_p_col_count=2&p_p_isolated=1&currentURL=%2Fweb%2Fguest%2Fcotizaciones')
    RATES=$(echo "$html_contents" | xmllint --html --xpath "//p[text()='DÃ³lar eBROU']/../../..//p[@class='valor']/text()" - | tr ',' '.' | tr '\n' ' ')
    BUY=$($ROUND_TWO "$(echo "$RATES" | awk '{print $1}')")
    SELL=$($ROUND_TWO "$(echo "$RATES" | awk '{print $2}')")
elif [ "$EXCHANGE" = "itau" ]; then
    EXCHANGE_NAME="Itaú"
    xml_contents=$($FETCH https://www.itau.com.uy/inst/aci/cotiz.xml)
    BUY=$(echo "$xml_contents" | xmllint --xpath "//cotizacion[moneda='LINK']/compra/text()" - | tr ',' '.')
    SELL=$(echo "$xml_contents" | xmllint --xpath "//cotizacion[moneda='LINK']/venta/text()" - | tr ',' '.')
elif [ "$EXCHANGE" = "bcu" ]; then
    EXCHANGE_NAME="Banco Central del Uruguay"
    # BCU might not have an exchange published for today (if it's a non working day or if they haven't updated the exchange for today yet). Their website defaults to showing the data for the last available day, which is the actual rate (as rates are only updated on working days).
    # We assume we'll find some exchange in the last 7 days, which seems safe as the longest non working day streak is < 7.
    body='{"KeyValuePairs": {"Monedas": [{"Val": "2225","Text": "DLS. USA BILLETE"}],"FechaDesde": "'"$(seven_days_ago)"'","Grupo": "2"}}'
    url='https://www.bcu.gub.uy/_layouts/15/BCU.Cotizaciones/handler/CotizacionesHandler.ashx?op=getcotizaciones'
    response=$(FETCH_POST "$body" "$url")

    n_rates="$(echo "$response" | jq '.cotizacionesoutlist.Cotizaciones | length')"
    if [ "$n_rates" -eq 0 ]; then
        echo "Error: No exchange rate found in the past 7 days. Try waiting or editing the code to fetch a wider range of dates."
        exit 1
    fi

    BUY=$(echo "$response" | jq '.cotizacionesoutlist.Cotizaciones | sort_by(.Fecha) | last | .TCC')
    SELL=$(echo "$response" | jq '.cotizacionesoutlist.Cotizaciones | sort_by(.Fecha) | last | .TCV')
else
    # EXCHANGE validation failed.
    exit_instructions
    exit 1
fi

#
# Compute the mean
#
MEAN_EXPR="(${BUY} + ${SELL}) / 2"

# --mathlib is for bc to use decimals properly
CALC="bc --mathlib"
# Trim trailing zeros with sed substitution if decimal point is present.
MEAN=$(echo "${MEAN_EXPR}" | $CALC | sed -E '/\./ s/\.?0+$//')


# Thanks SO
beginswith() { case "$2" in "$1"*) true ;; *) false ;; esac }


if [ "$AMOUNT" != "" ]; then
    if beginswith "$" "$AMOUNT"; then
        # The `cut` command drops the initial `$` from the input.
        AMOUNT=$(echo "$AMOUNT" | cut -c 2-)
        UYU=$($ROUND_TWO "$AMOUNT")
        USD=$($ROUND_TWO "$(echo "(${UYU} / ${MEAN})" | $CALC)")
        INPUT_CURRENCY=UYU
        TRANSA_CURRENCY=USD
        TRANSA_VALUE="$USD"
    else
        USD=$($ROUND_TWO "$AMOUNT")
        UYU=$($ROUND_TWO "$(echo "(${USD} * ${MEAN})" | $CALC)")
        INPUT_CURRENCY=USD
        TRANSA_CURRENCY=UYU
        TRANSA_VALUE="$UYU"
    fi
else
    # So that we don't have unbound local variables when calling our output function.
    UYU=""
    USD=""
    INPUT_CURRENCY=""
    TRANSA_CURRENCY=""
    TRANSA_VALUE=""
fi

plain_text_output() {
    AMOUNT=${1}
    INPUT_CURRENCY=${2}
    EXCHANGE=${3}
    EXCHANGE_NAME=${4}
    BUY=${5}
    SELL=${6}
    MEAN=${7}
    MEAN_EXPR=${8}
    USD=${9}
    UYU=${10}
    TRANSA_CURRENCY=${11}
    TRANSA_VALUE=${12}

    if [ "$AMOUNT" != "" ]; then
        TRANSA_TEXT="\n\nTRANSA: US\$ $USD = $ $UYU"
    else
        TRANSA_TEXT=""
    fi
    /usr/bin/printf "$EXCHANGE_NAME compra y venta: $BUY, $SELL\n$MEAN_EXPR = $MEAN$TRANSA_TEXT"
}

json_output() {
    AMOUNT=${1}
    INPUT_CURRENCY=${2}
    EXCHANGE=${3}
    EXCHANGE_NAME=${4}
    BUY=${5}
    SELL=${6}
    MEAN=${7}
    MEAN_EXPR=${8}
    USD=${9}
    UYU=${10}
    TRANSA_CURRENCY=${11}
    TRANSA_VALUE=${12}

    if [ "$AMOUNT" != "" ]; then
        # The rounded input is what's actually being used in the transa, therefore we return it here as input.
        input_value="$($ROUND_TWO "$AMOUNT")"
        input_currency="\"$INPUT_CURRENCY\""
        transa_value="$TRANSA_VALUE"        
        transa_currency="\"$TRANSA_CURRENCY\""
    else
        input_value=null
        input_currency=null
        transa_value=null 
        transa_currency=null       
    fi
    created_at="\"$(date -u +%Y-%m-%dT%H:%M:%S%Z)\""
    
    # First result
    bank="\"$EXCHANGE\""
    buy=$BUY
    sell=$SELL
    computed_mean=$MEAN

    SEP="  "

    START_JSON="{\n"
    ROOT_FIELDS="$SEP\"input_value\": $input_value,\n$SEP\"input_currency\": $input_currency,\n$SEP\"created_at\": $created_at,\n$SEP\"results\": [\n"
    
    INNER_SEP="$SEP$SEP$SEP"
    RESULT_START="$SEP$SEP{\n"
    RESULT_FIELDS="$INNER_SEP\"bank\": $bank,\n$INNER_SEP\"buy\": $buy,\n$INNER_SEP\"sell\": $sell,\n$INNER_SEP\"computed_mean\": $computed_mean,\n$INNER_SEP\"transa_value\": $transa_value,\n$INNER_SEP\"transa_currency\": $transa_currency\n"
    RESULT_END="$SEP$SEP}\n$SEP]"
    RESULT="$RESULT_START$RESULT_FIELDS$RESULT_END"  
    
    END_JSON="\n}"

    /usr/bin/printf "$START_JSON$ROOT_FIELDS$RESULT$END_JSON"    
}

if [ "$json_flag" = true ]; then
    # Compute plaintext transa output
    OUTPUT=$(json_output "$AMOUNT" "$INPUT_CURRENCY" "$EXCHANGE" "$EXCHANGE_NAME" "$BUY" "$SELL" "$MEAN" "$MEAN_EXPR" "$USD" "$UYU" "$TRANSA_CURRENCY" "$TRANSA_VALUE")
else
    # Compute JSON transa output
    OUTPUT=$(plain_text_output "$AMOUNT" "$INPUT_CURRENCY" "$EXCHANGE" "$EXCHANGE_NAME" "$BUY" "$SELL" "$MEAN" "$MEAN_EXPR" "$USD" "$UYU" "$TRANSA_CURRENCY" "$TRANSA_VALUE")    
fi

# Print final output to stdout
/usr/bin/printf '%b\n' "$OUTPUT"

