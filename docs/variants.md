# Variants

## Notation:

### Number of Blocks
Symbols _Na_, _Nm_, _Nc_, _Nh_ represent the number of complete blocks of associated data, plaintext, ciphertext, and hash message, respectively.

### Incomplete Blocks
Symbols _Ina_, _Inm_, _Inc_, _Inh_ represent the completeness of a block of of associated data, plaintext, ciphertext, and hash message, respectively. These are binary variables equal to 1 if the last block is incomplete and 0 if it is complete.

### Valid Bytes
Symbols _Bla_, _Blm_, _Blc_, _Blh_ represent the number of valid bytes in an incomplete block of associated data, plaintext, ciphertext, and hash message, respectively.

## 1. v1
aceae128v1 & acehash256v1

### A. Design goal.
Support for authenticated encryption, decryption, and hashing. Balance throughput and area use by unfolding SB-64 function loop, but maintaining ACE-permutation folded.

#### Resource Use
<pre>
< 2000 LUTs
< 4000 FFs
No BRAMs 
No DSP units
</pre>

### B. Supported maximum sizes of inputs.

##### Authenticated Encryption

No limit.

##### Authenticated Decryption

No limit.

##### Hashing

No limit.

### C. Reference software implementation.

A copy of the original authors' reference implementation can be found in:
<pre>
src_sw/crypto_aead/aceae128v1/ref/
src_sw/crypto_hash/acehash256v1/ref/
</pre>

For all their code and documents, [see their team website](https://uwaterloo.ca/communications-security-lab/lwc/ace).

### D. Non-default values of generics and constants.

No changes to generics and constants of synthesizable sources.

Changed LWC testbench KAT file paths to absolute paths:
<pre>
G_FNAME_PDI
G_FNAME_SDI
G_FNAME_DO
</pre>

### E. Block Sizes
<pre>
AD block size:                    64 bits
Plaintext/Ciphertext block size:  64 bits
Hash block size:                  64 bits
</pre>

### F. Execution times (in clock cycles)

#### Authenticated Encryption

##### With no incomplete last blocks:
= 60 + 18*_Na_ + 16 + 18*_Nm_ + 16 + 36

= 18*_Na_ + 18*_Nm_ + 128

##### With incomplete last blocks:
= 60 + 18*_Na_ + 18*_Nm_ + 36

= 18*_Na_ + 18*_Nm_ + 96

#### Authenticated Decryption

##### With no incomplete last blocks:
= 60 + 18*_Na_ + 16 + 18*_Nc_ + 16 + 37

= 18*_Na_ + 18*_Nc_ + 129

##### With incomplete last blocks:
= 60 + 18*_Na_ + 18*_Nc_ + 37

= 18*_Na_ + 18*_Nc_ + 97

#### Hashing

##### With no incomplete last blocks:
= 1 + 16 + 18*_Nh_ + 16 + 2 + 16 + 2 + 16 + 2 + 16 + 2

= 18*_Nh_ + 89

##### With incomplete last blocks:
= 1 + 16 + 18*_Nh_ + 2 + 16 + 2 + 16 + 2 + 16 + 2

= 18*_Nh_ + 81

### G. Latencies

#### Authenticated Encryption
No clock cycle latency.

#### Authenticated Decryption
No clock cycle latency.

#### H. Difference between execution times for a new key and the same key.

#### Authenticated Encryption
Key reuse saves four cycles key read cycles plus one idle cycle, for a total of five saved cycles.

#### Authenticated Decryption
Key reuse saves four cycles key read cycles plus one idle cycle, for a total of five saved cycles.
