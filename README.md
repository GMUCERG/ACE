# ACE
This is an implementation of a [NIST Lightweight Cryptography](https://csrc.nist.gov/projects/lightweight-cryptography) [Round 2](https://csrc.nist.gov/Projects/lightweight-cryptography/round-2-candidates) candidate, [ACE](https://uwaterloo.ca/communications-security-lab/lwc/ace).

## Top-level Repository Structure
### Files:
* [LICENSE.txt](./LICENSE.txt)  - License and authors.
* [LICENSE](./LICENSE)          - Text of license applied to this repository, implementation, documentation, etc.
* [README.md](./README.md)      - This brief overview of the repository and implementation. 

### Directories:
* [bd](./bd)           - Block diagrams.
* [docs](./docs)       - Documentation.
* [KAT](./KAT)         - Known-answer tests.
* [results](./results) - Preliminary benchmarking results.
* [scripts](./scripts) - Simulation scripts.
* [src_rtl](./src_rtl) - Synthesizable source RTL code.
* [src_sw](./src_sw)   - Reference software implementation.
* [src_tb](./src_tb)   - Testbench and non-synthesizable source code.

## Author(s)
#### GMU CERG members:
LWC Development Package. See files for specific authors/contributors.

#### Omar Zabala-Ferrera, GMU CERG:
ACE (aceae128v1 & acehash256v1) implementation using LWC Development Package.

## Credits
Thanks to Dr. Kris Gaj and the rest of the GMU CERG group for their help and patience as I completed my first contribution to the team.

PDF documents were generated using NPM package [md-to-pdf](https://www.npmjs.com/package/md-to-pdf) by [Simon Hänisch](https://www.npmjs.com/~simonhaenisch).