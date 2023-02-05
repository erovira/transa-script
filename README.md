# transa-script
Shell script to compute the Itaú & BROU mean USD/UYU exchange rate.

## Usage

```
# Get exchange rates only
bash transa.sh
bash transa.sh itau
bash transa.sh brou

# Exchange rates + calculation for a certain amount
bash transa.sh <amount>
bash transa.sh <amount> brou
bash transa.sh <amount> itau
```

## Examples

### Exchange rates only

```
➜ bash transa.sh
Itaú compra y venta: 37.90, 40.30
(37.90 + 40.30) / 2 = 39.10

➜ bash transa.sh brou
eBROU compra y venta: 38.40000, 39.80000
(38.40000 + 39.80000) / 2 = 39.10
```

### Provide an amount in USD (default)

```
➜ bash transa.sh 850
Itaú compra y venta: 37.90, 40.30
(37.90 + 40.30) / 2 = 39.10

TRANSA: U$S 850.00 = $ 33235.00

➜ bash transa.sh 850 brou
eBROU compra y venta: 38.40000, 39.80000
(38.40000 + 39.80000) / 2 = 39.10

TRANSA: U$S 850.00 = $ 33235.00
```

### Provide an amount in UYU

```
➜ bash transa.sh \$50000
Itaú compra y venta: 37.90, 40.30
(37.90 + 40.30) / 2 = 39.10

TRANSA: U$S 1278.77 = $ 50000.00

➜ bash transa.sh \$50000 brou
eBROU compra y venta: 38.40000, 39.80000
(38.40000 + 39.80000) / 2 = 39.10

TRANSA: U$S 1278.77 = $ 50000.00
```

⚠️ Note that you'll have to escape the `$` character with a `\`

## Lazy mode

If you'd like to type `transa` instead of `bash transa.sh` do the following:

```
chmod +x transa.sh # Make it executable
cp transa.sh $HOME/.local/bin/transa # Make it detectable by your shell
```
Note; you _may_ need to add `$HOME/.local/bin/` to your $PATH.
