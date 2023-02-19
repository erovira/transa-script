# transa-script
Shell script to compute the Itaú & BROU mean [USD](https://en.wikipedia.org/wiki/United_States_dollar)/[UYU](https://en.wikipedia.org/wiki/Uruguayan_peso) exchange rate.

## Usage

```
# Get exchange rates only
transa
transa itau
transa brou

# Exchange rates + calculation for a certain amount
transa <amount>
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
