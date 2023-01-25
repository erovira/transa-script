# transa-script
Shell script to compute the Itaú & BROU mean USD/UYU exchange rate.

## Usage

```sh
# Get exchange rates only
sh transa.sh
sh transa.sh itau
sh transa.sh brou

# Exchange rates + calculation for a certain amount
sh transa.sh <amount>
sh transa.sh <amount> brou
sh transa.sh <amount> itau
```

## Examples

### Exchange rates only

```sh
➜ sh transa.sh
Itaú compra y venta: 37.90, 40.30
(37.90 + 40.30) / 2 = 39.10

➜ sh transa.sh brou
eBROU compra y venta: 38.40000, 39.80000
(38.40000 + 39.80000) / 2 = 39.10
```

### Provide an amount in USD (default)

```sh
➜ sh transa.sh 850
Itaú compra y venta: 37.90, 40.30
(37.90 + 40.30) / 2 = 39.10

TRANSA: U$S 850.00 = $ 33235.00

➜ sh transa.sh 850 brou
eBROU compra y venta: 38.40000, 39.80000
(38.40000 + 39.80000) / 2 = 39.10

TRANSA: U$S 850.00 = $ 33235.00
```

### Provide an amount in UYU

```sh
➜ sh transa.sh \$50000
Itaú compra y venta: 37.90, 40.30
(37.90 + 40.30) / 2 = 39.10

TRANSA: U$S 1278.77 = $ 50000.00

➜ sh transa.sh \$50000 brou
eBROU compra y venta: 38.40000, 39.80000
(38.40000 + 39.80000) / 2 = 39.10

TRANSA: U$S 1278.77 = $ 50000.00
```

⚠️ Note that you'll have to escape the `$` character with a `\`

## Lazy mode

If you'd like to type `transa` instead of `sh transa.sh` do the following:

```sh
chmod +x transa.sh # Make it executable
cp transa.sh /usr/local/bin/transa # Make it detectable by your shell
```
