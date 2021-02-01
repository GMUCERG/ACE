------------------------------------------------------------------------------
---- ACE AEAD and Hash Package                                            ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This package defines constants and types used throughout the rest of ----
---- the project for the various ACE and CryptoCore related items.        ----
----                                                                      ----
---- To Do:                                                               ----
----                                                                      ----
----                                                                      ----
---- Author(s):                                                           ----
----   - Omar Zabala-Ferrera, ozabalaf@gmu.edu                            ----
----                                                                      ----
---- Credit:                                                              ----
----   Derived from LWC development package:                              ----
----   https://github.com/GMUCERG/LWC/                                    ----
----   design_pkg.vhd                                                     ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (C) 2020 Authors                                           ----
----                                                                      ----
---- This program is free software: you can redistribute it and/or modify ----
---- it under the terms of the GNU General Public License as published by ----
---- the Free Software Foundation, either version 3 of the License, or    ----
---- (at your option) any later version.                                  ----
----                                                                      ----
---- This program is distributed in the hope that it will be useful,      ----
---- but WITHOUT ANY WARRANTY; without even the implied warranty of       ----
---- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        ----
---- GNU General Public License for more details.                         ----
----                                                                      ----
---- You should have received a copy of the GNU General Public License    ----
---- along with this program. If not, see <http://www.gnu.org/licenses/>. ----
----                                                                      ----
------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE design_pkg IS

  ----------------------------------------------------------------------------
  -- UTILITY FUNCTIONS
  -- Calculate log2 of N and round up.
  FUNCTION log2_ceil (N : NATURAL) RETURN NATURAL;
  ----------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  -- ACE SPEC PARAMETERS
  CONSTANT RATE : INTEGER := 64; -- Rate 'r'.

  CONSTANT ACE_STATE_SIZE : INTEGER := 320; -- State size.
  CONSTANT SR_SIZE        : INTEGER := RATE;
  CONSTANT SC_SIZE        : INTEGER := ACE_STATE_SIZE - RATE; -- Rest of state

  CONSTANT KEY_SIZE     : INTEGER := 128; -- Key size 'k'.
  CONSTANT NPUB_SIZE    : INTEGER := 128; -- Nonce size 'n'. 
  CONSTANT TAG_SIZE     : INTEGER := 128; -- Tag size 't'
  CONSTANT HASH_SIZE    : INTEGER := 256; -- Hash size 'h'. 
  CONSTANT IV_SIZE      : INTEGER := 24;  -- IV size 'iv'
  CONSTANT ACE_STEPS    : INTEGER := 16;  -- ACE-perm ACE-steps.
  CONSTANT SB64_ROUNDS  : INTEGER := 8;   -- SB-64 rounds 'u'.
  CONSTANT HASH_OUTPUTS : INTEGER := 4;   -- SB-64 rounds 'u'.

  -- HELPFUL SIZE CONSTANTS
  CONSTANT HALF_WORD_SIZE   : INTEGER := RATE / 2;
  CONSTANT WORD_SIZE        : INTEGER := HALF_WORD_SIZE * 2;
  CONSTANT DOUBLE_WORD_SIZE : INTEGER := WORD_SIZE * 2;

  -- LWC API PARAMETERS:
  CONSTANT CCSW    : INTEGER := HALF_WORD_SIZE;
  CONSTANT CCW     : INTEGER := HALF_WORD_SIZE;
  CONSTANT CCWdiv8 : INTEGER := CCW/8;

  -- HELPFUL DERIVED SIZES/COUNTS
  CONSTANT KEY_WORDS       : INTEGER := KEY_SIZE / WORD_SIZE;
  CONSTANT KEY_HALF_WORDS  : INTEGER := KEY_SIZE / HALF_WORD_SIZE;
  CONSTANT NPUB_WORDS      : INTEGER := NPUB_SIZE / WORD_SIZE;
  CONSTANT NPUB_HALF_WORDS : INTEGER := NPUB_SIZE / HALF_WORD_SIZE;
  CONSTANT TAG_WORDS       : INTEGER := TAG_SIZE / WORD_SIZE;
  CONSTANT TAG_HALF_WORDS  : INTEGER := TAG_SIZE / HALF_WORD_SIZE;
  CONSTANT HASH_WORDS      : INTEGER := HASH_SIZE / WORD_SIZE;
  CONSTANT HASH_HALF_WORDS : INTEGER := HASH_SIZE / HALF_WORD_SIZE;
  CONSTANT BDIO_HALF_WORDS : INTEGER := WORD_SIZE / CCW;

  -- COUNT PARAMETERS:
  CONSTANT ACE_STEP_CNT_WIDTH : INTEGER := log2_ceil(ACE_STEPS);
  CONSTANT KNT_HW_CNT_WIDTH   : INTEGER := log2_ceil(KEY_HALF_WORDS);
  CONSTANT HASH_SQZ_CNT_WIDTH : INTEGER := log2_ceil(HASH_OUTPUTS);
  --CONSTANT KEY_WORDS_CNT_WIDTH : INTEGER := log2_ceil(KEY_WORDS);

  -- ACE PERMUTATION CONSTANTS
  -- (sc0, sc1, sc2) (rc0, rc1, rc2)
  CONSTANT RSC_SIZE         : INTEGER := 8; -- A byte.
  CONSTANT RSC_CNT_PER_STEP : INTEGER := 6; -- sc + rc triplets.
  CONSTANT RSC_ADDR_WIDTH   : INTEGER := ACE_STEP_CNT_WIDTH;
  CONSTANT RSC_ROM_O_SIZE   : INTEGER := RSC_CNT_PER_STEP * RSC_SIZE;

  -- HELPFUL RANGE SUBTYPES
  SUBTYPE HALF_WORD_RANGE IS NATURAL RANGE HALF_WORD_SIZE - 1 DOWNTO 0;
  SUBTYPE WORD_RANGE IS NATURAL RANGE WORD_SIZE - 1 DOWNTO 0;
  SUBTYPE DOUBLE_WORD_RANGE IS NATURAL RANGE DOUBLE_WORD_SIZE - 1 DOWNTO 0;
  SUBTYPE ACE_STATE_RANGE IS NATURAL RANGE ACE_STATE_SIZE - 1 DOWNTO 0;

  SUBTYPE W_HW0_RANGE IS NATURAL RANGE WORD_SIZE - 1 DOWNTO HALF_WORD_SIZE;
  SUBTYPE W_HW1_RANGE IS NATURAL RANGE HALF_WORD_SIZE - 1 DOWNTO 0;
  SUBTYPE DW_W0_RANGE IS NATURAL RANGE DOUBLE_WORD_SIZE - 1 DOWNTO WORD_SIZE;
  SUBTYPE DW_W1_RANGE IS NATURAL RANGE WORD_SIZE - 1 DOWNTO 0;

  SUBTYPE RSC_RANGE IS NATURAL RANGE RSC_SIZE - 1 DOWNTO 0;

  -- HELPFUL VECTOR SUBTYPES
  SUBTYPE HALF_WORD IS STD_LOGIC_VECTOR(HALF_WORD_RANGE);
  SUBTYPE WORD IS STD_LOGIC_VECTOR(WORD_RANGE);
  SUBTYPE DOUBLE_WORD IS STD_LOGIC_VECTOR(DOUBLE_WORD_RANGE);
  SUBTYPE ACE_STATE_V IS STD_LOGIC_VECTOR(ACE_STATE_RANGE);
  SUBTYPE ACE_SR_V IS STD_LOGIC_VECTOR(SR_SIZE - 1 DOWNTO 0);
  SUBTYPE ACE_SC_V IS STD_LOGIC_VECTOR(SC_SIZE - 1 DOWNTO 0);

  SUBTYPE RSC IS STD_LOGIC_VECTOR (RSC_RANGE);

  -- HELPFUL CONSTANT VECTORS
  CONSTANT BDI_SIZE_0 : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0)
  := (OTHERS => '0');
  CONSTANT ALL_BDI_BYTES_VALID : STD_LOGIC_VECTOR (CCWdiv8 - 1 DOWNTO 0)
  := (OTHERS => '1');

  CONSTANT IV_CONST          : WORD      := X"8040400000000000";
  CONSTANT ACE_PAD_WORD      : WORD      := X"8000000000000000";
  CONSTANT ACE_PAD_HALF_WORD : HALF_WORD := X"80000000";

  -- Domain separartor bits
  CONSTANT DS_BITS_ZERO    : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
  CONSTANT DS_BITS_AD      : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
  CONSTANT DS_BITS_ENC_DEC : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
  ----------------------------------------------------------------------------

  -- Location of word A within state
  SUBTYPE STATE_WORD_A_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (0 * WORD_SIZE) - 1 DOWNTO ACE_STATE_SIZE - (1 * WORD_SIZE);

  -- Location of word B within state
  SUBTYPE STATE_WORD_B_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (1 * WORD_SIZE) - 1 DOWNTO ACE_STATE_SIZE - (2 * WORD_SIZE);

  -- Location of word C within state
  SUBTYPE STATE_WORD_C_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (2 * WORD_SIZE) - 1 DOWNTO ACE_STATE_SIZE - (3 * WORD_SIZE);

  -- Location of word D within state
  SUBTYPE STATE_WORD_D_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (3 * WORD_SIZE) - 1 DOWNTO ACE_STATE_SIZE - (4 * WORD_SIZE);

  -- Location of word E within state
  SUBTYPE STATE_WORD_E_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (4 * WORD_SIZE) - 1 DOWNTO ACE_STATE_SIZE - (5 * WORD_SIZE);

  -- Location of IV within state
  SUBTYPE STATE_IV_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (1 * WORD_SIZE) - 1 DOWNTO ACE_STATE_SIZE - (1 * WORD_SIZE) - IV_SIZE;

  -- Location of Sr high portion within state
  SUBTYPE STATE_SRH_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - 1 DOWNTO ACE_STATE_SIZE - HALF_WORD_SIZE;

  -- Location of Sr low portion within state
  SUBTYPE STATE_SRL_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (4 * HALF_WORD_SIZE) - 1 DOWNTO ACE_STATE_SIZE - (5 * HALF_WORD_SIZE);

  -- Location of Sc high portion within state
  SUBTYPE STATE_SCH_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - HALF_WORD_SIZE - 1 DOWNTO ACE_STATE_SIZE - (4 * HALF_WORD_SIZE);

  -- Location of Sc low portion within state
  SUBTYPE STATE_SCL_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (5 * HALF_WORD_SIZE) - 1 DOWNTO 0;

  -- Location of T1 within state
  SUBTYPE STATE_TAG1_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - 1 DOWNTO ACE_STATE_SIZE - WORD_SIZE;

  -- Location of T0 within state
  SUBTYPE STATE_TAG0_RANGE IS NATURAL RANGE
  ACE_STATE_SIZE - (2 * WORD_SIZE) - 1 DOWNTO ACE_STATE_SIZE - (3 * WORD_SIZE);
  ----------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  -- Combine Sr and Sc state portions into a whole state vector
  FUNCTION state_from_sr_sc(sr : STD_LOGIC_VECTOR; sc : STD_LOGIC_VECTOR
  ) RETURN STD_LOGIC_VECTOR;

  -- Swap high and low half-words of a word.
  FUNCTION swap_w_hws(vec : WORD) RETURN WORD;
  -- Swap high and low half-words of of both double-word words
  FUNCTION swap_dw_hws(vec : DOUBLE_WORD) RETURN DOUBLE_WORD;

  -- Get Sr portion of the ACE state
  FUNCTION sr_from_state(state_vector : ACE_STATE_V) RETURN ACE_SR_V;
  -- Get Sc portion of the ACE state
  FUNCTION sc_from_state(state_vector : ACE_STATE_V) RETURN ACE_SC_V;
  -- Get tag portion of the ACE state
  FUNCTION tag_from_state(state_vector : ACE_STATE_V) RETURN DOUBLE_WORD;

  --! Padding the current word.
  FUNCTION padd(bdi, bdi_valid_bytes, bdi_pad_loc : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;
  --! Replace the invalid msg portion with corresponding portion from another vector.
  FUNCTION repl_invalid(msg_v, msg_i, msg_valid_bytes, msg_pad_loc : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;
  --! Return max value
  FUNCTION max(a, b : INTEGER) RETURN INTEGER;

END design_pkg;

PACKAGE BODY design_pkg IS

  --! Swap the order of half words in a word for proper input/output order
  FUNCTION swap_w_hws(vec : WORD) RETURN WORD IS
    VARIABLE res            : WORD;
  BEGIN
    res := vec(HALF_WORD_SIZE - 1 DOWNTO 0) &
      vec(WORD_SIZE - 1 DOWNTO HALF_WORD_SIZE);
    RETURN res;
  END FUNCTION;

  --! Swap the order of half words in a double word for proper input/output order
  FUNCTION swap_dw_hws(vec : DOUBLE_WORD) RETURN DOUBLE_WORD IS
    VARIABLE res             : DOUBLE_WORD;
  BEGIN
    res := swap_w_hws(vec(WORD_SIZE - 1 DOWNTO 0)) &
      swap_w_hws(vec(DOUBLE_WORD_SIZE - 1 DOWNTO WORD_SIZE));
    RETURN res;
  END FUNCTION;

  -- Get Sr part of the ACE state
  FUNCTION sr_from_state(state_vector : ACE_STATE_V) RETURN ACE_SR_V IS
    VARIABLE sr                         : ACE_SR_V;
  BEGIN
    sr := state_vector(STATE_SRH_RANGE) & state_vector(STATE_SRL_RANGE);
    RETURN sr;
  END FUNCTION;

  -- Get Sc part of the ACE state
  FUNCTION sc_from_state(state_vector : ACE_STATE_V) RETURN ACE_SC_V IS
    VARIABLE sc                         : ACE_SC_V;
  BEGIN
    sc := state_vector(STATE_SCH_RANGE) & state_vector(STATE_SCL_RANGE);
    RETURN sc;
  END FUNCTION;

  -- Combine Sr and Sc state portions into a whole state vector
  FUNCTION state_from_sr_sc(sr : STD_LOGIC_VECTOR; sc : STD_LOGIC_VECTOR
  ) RETURN STD_LOGIC_VECTOR IS
    VARIABLE state_combined : ACE_STATE_V;
  BEGIN
    state_combined(STATE_SRH_RANGE) := sr(SR_SIZE - 1 DOWNTO HALF_WORD_SIZE);
    state_combined(STATE_SRL_RANGE) := sr(HALF_WORD_SIZE - 1 DOWNTO 0);
    state_combined(STATE_SCH_RANGE) := sc(SC_SIZE - 1 DOWNTO SC_SIZE - (3 * HALF_WORD_SIZE));
    state_combined(STATE_SCL_RANGE) := sc(SC_SIZE - 3 * HALF_WORD_SIZE - 1 DOWNTO 0);
    RETURN state_combined;
  END FUNCTION;

  -- Get tag part of the ACE state
  FUNCTION tag_from_state(state_vector : ACE_STATE_V) RETURN DOUBLE_WORD IS
    VARIABLE tag                         : DOUBLE_WORD;
  BEGIN
    tag := state_vector(STATE_TAG1_RANGE) & state_vector(STATE_TAG0_RANGE);
    RETURN tag;
  END FUNCTION;

  -- Log of base 2 of N
  -- Taken from LWC API code.
  FUNCTION log2_ceil (N : NATURAL) RETURN NATURAL IS
  BEGIN
    IF (N = 0) THEN
      RETURN 0;
    ELSIF N <= 2 THEN
      RETURN 1;
    ELSE
      IF (N MOD 2 = 0) THEN
        RETURN 1 + log2_ceil(N/2);
      ELSE
        RETURN 1 + log2_ceil((N + 1)/2);
      END IF;
    END IF;
  END FUNCTION log2_ceil;

  --! Padd the data with 0x80 Byte if pad_loc is set.
  FUNCTION padd(bdi, bdi_valid_bytes, bdi_pad_loc : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE res                                    : STD_LOGIC_VECTOR(bdi'length - 1 DOWNTO 0) := (OTHERS => '0');
  BEGIN

    FOR i IN 0 TO (bdi_valid_bytes'length - 1) LOOP
      IF (bdi_valid_bytes(i) = '1') THEN
        res(8 * (i + 1) - 1 DOWNTO 8 * i) := bdi(8 * (i + 1) - 1 DOWNTO 8 * i);
      ELSIF (bdi_pad_loc(i) = '1') THEN
        res(8 * (i + 1) - 1 DOWNTO 8 * i) := x"80";
      END IF;
    END LOOP;

    RETURN res;
  END FUNCTION;

  --! Replace the invalid msg portion with corresponding portion from another vector. Includes XORed padding.
  FUNCTION repl_invalid(msg_v, msg_i, msg_valid_bytes, msg_pad_loc : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE res                                                     : STD_LOGIC_VECTOR(msg_v'length - 1 DOWNTO 0);
  BEGIN

    FOR i IN 0 TO (msg_valid_bytes'length - 1) LOOP
      IF (msg_valid_bytes(i) = '1') THEN
        res(8 * (i + 1) - 1 DOWNTO 8 * i) := msg_v(8 * (i + 1) - 1 DOWNTO 8 * i);
      ELSE
        IF (msg_pad_loc(i) = '1') THEN
          res(8 * (i + 1) - 1 DOWNTO 8 * i) := x"80" XOR msg_i(8 * (i + 1) - 1 DOWNTO 8 * i);
        ELSE
          res(8 * (i + 1) - 1 DOWNTO 8 * i) := msg_i(8 * (i + 1) - 1 DOWNTO 8 * i);
        END IF;
      END IF;
    END LOOP;

    RETURN res;
  END FUNCTION;

  --! Return max value.
  FUNCTION max(a, b : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (a >= b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END FUNCTION;

END PACKAGE BODY design_pkg;
