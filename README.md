# transa-script
Shell script to compute the exchange median USD/UYU exchange rate


## Example usage


### No arguments
```
➜ sh transa.sh
Itaú compra y venta: 42.80, 44.70
(42.80 + 44.70) / 2 = 43.75
```


### Provide an amount in USD
```
➜ sh transa.sh 850
Itaú compra y venta: 42.80, 44.70
(42.80 + 44.70) / 2 = 43.75
TRANSA: U$S 850 = $ 37187.50
```

## Lazy mode
If you'd like to type `transa` instead of `sh transa.sh` do the following:

```
chmod +x transa.sh # Make it executable
cp transa.sh /usr/local/bin/transa # Make it detectable by your shell
```
