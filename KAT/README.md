# KAT Vectors
These KAT vector files were generated with the GMU CERG tool [cryptotvgen](https://github.com/GMUCERG/LWC/tree/master/software/cryptotvgen):

```
cryptotvgen --prepare_libs
```
```
cryptotvgen --aead aceae128v1 --hash acehash256v1 --gen_benchmark --block_size 128 --block_size_ad 128 --block_size_msg_digest 256 --human_readable
```