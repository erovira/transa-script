# transa-script
Shell script to compute the Itaú & BROU mean [USD](https://en.wikipedia.org/wiki/United_States_dollar)/[UYU](https://en.wikipedia.org/wiki/Uruguayan_peso) exchange rate.

## Usage

```
# General usage:
transa [<amount>] [itau|brou] [-j|--json]"

# Get exchange rates only
transa # Defaults to itau
transa itau
transa brou

# Exchange rates + calculation for a certain amount
transa <amount> # Defaults to itau
transa <amount> brou
transa <amount> itau
```

## Installation

```
curl -s -o $HOME/.local/bin/transa https://raw.githubusercontent.com/erovira/transa-script/main/transa.sh && \
chmod +x $HOME/.local/bin/transa
```
Then you'll be able to call transa from your terminal such as in the examples below.

Notes:
- Only install and use the script if you trust it.
- If `$HOME/.local/bin` is not on your $PATH, you'll have to add it.


## Structured json output schema
```
{
  "input_value":    float,  # null if no input.
  "input_currency": string, # Possible values: "UYU", "USD", null if no input.
  "created_at":     string, # Date the script completed in ISO 8601 format.
  "results": [
    {
      "bank":             string, # Possible values: "itau", "brou"
      "buy":              float,
      "sell":             float,
      "computed_mean":    float,
      "transa_value":     float,  # null if no input.
      "transa_currency":  string, # Possible values: "UYU", "USD", null if no input.
    }
  ]
}
```

## Examples

### Exchange rates only

```
➜ transa
Itaú compra y venta: 38.20, 40.10
(38.20 + 40.10) / 2 = 39.15

➜ transa brou
eBROU compra y venta: 38.35, 39.95
(38.35 + 39.95) / 2 = 39.15
```

### Provide an amount in USD (default)

```
➜ transa 850
Itaú compra y venta: 38.20, 40.10
(38.20 + 40.10) / 2 = 39.15

TRANSA: US$ 850.00 = $ 33277.50

➜ transa 850 brou
eBROU compra y venta: 38.35, 39.95
(38.35 + 39.95) / 2 = 39.15

TRANSA: US$ 850.00 = $ 33277.50
```

### Provide an amount in UYU

```
➜ transa \$50000
Itaú compra y venta: 38.20, 40.10
(38.20 + 40.10) / 2 = 39.15

TRANSA: US$ 1277.14 = $ 50000.00

➜ transa \$50000 brou
eBROU compra y venta: 38.35, 39.95
(38.35 + 39.95) / 2 = 39.15

TRANSA: US$ 1277.14 = $ 50000.00
```

⚠️ Note that you'll have to escape the `$` character with a `\`

### Structured JSON output
```
➜ transa 1000 brou --json
{
  "input_value": 1000.00,
  "input_currency": "USD",
  "created_at": "2024-04-29T00:09:59UTC",
  "results": [
    {
      "bank": "brou",
      "buy": 37.45,
      "sell": 38.95,
      "computed_mean": 38.2,
      "transa_value": 38200.00,
      "transa_currency": "UYU"
    }
  ]
}
```
