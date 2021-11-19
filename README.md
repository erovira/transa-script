# transa-script
Shell script to compute the Itaú mean USD/UYU exchange rate


## Example usage


### No arguments
```
➜ sh transa.sh
Itaú compra y venta: 42.80, 44.70
(42.80 + 44.70) / 2 = 43.75
```


### Provide an amount in USD (default)
```
➜ sh transa.sh 850
Itaú compra y venta: 42.80, 44.70
(42.80 + 44.70) / 2 = 43.75
TRANSA: U$S 850 = $ 37187.50
```

### Provide an amount in UYU
```
➜ sh transa.sh \$50000
Itaú compra y venta: 43.30, 45.10
(43.30 + 45.10) / 2 = 44.20
TRANSA: U$S 1131.22 = $ 50000
```
⚠️ Note that you'll have to escape the `$` character with a `\`

## Lazy mode
If you'd like to type `transa` instead of `sh transa.sh` do the following:

```
chmod +x transa.sh # Make it executable
cp transa.sh /usr/local/bin/transa # Make it detectable by your shell
```
