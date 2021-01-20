# Assumptions

## A. Hardware description language(s) used.
VHDL-93

## B. GMU LWC development package files used.
|File name           |Used| Release number|Functional Modifications|
|--------------------|----|---------------|------------------------|
|NIST_LWAPI_pkg.vhd  |Yes |         v1.1.0|No                      |
|StepDownCountLd.vhd |Yes |         v1.1.0|No                      |
|data_piso.vhd       |Yes |         v1.1.0|No                      |
|data_sipo.vhd       |Yes |         v1.1.0|No                      |
|key_piso.vhd        |Yes |         v1.1.0|No                      |
|PreProcessor.vhd    |Yes |         v1.1.0|No                      |
|PostProcessor.vhd   |Yes |         v1.1.0|No                      |
|fwft_fifo.vhd       |Yes |         v1.1.0|No                      |
|LWC.vhd             |Yes |         v1.1.0|No                      |

## C. Supported types and order of segments.
|Operation |In/Out|Segments in order  |
|----------|------|-------------------|
|Encryption|Input |npub, ad, data     |
|Encryption|Output|data, tag          |
|Decryption|Input |npub, ad, data, tag|
|Decryption|Output|data               |
|Hashing   |Input |data               |
|Hashing   |Output|data               |

## D. Deviations from LWC Hardware API v1.1.0

### 1. Minimum compliance criteria.
No deviations from the minimum compliance criteria.

### 2. Interface
No deviations from the interface.

### 3. Protocol
No deviations from the protocol.

### 4. Timing
No deviations from the timing.