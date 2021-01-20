------------------------------------------------------------------------------
---- Teastbench for ACE-permutation approach.                             ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This testbench uses the ace_step and rsc_rom entities to execute     ----
---- and test ACE-permutations by doing 16 ACE-steps.                     ----
----                                                                      ----
---- To Do:                                                               ----
----                                                                      ----
----                                                                      ----
---- Author(s):                                                           ----
----   - Omar Zabala-Ferrera, ozabalaf@gmu.edu                            ----
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
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DESIGN_PKG.ALL;

ENTITY ace_permutation_tb IS
END ace_permutation_tb;

ARCHITECTURE ace_permutation_tb_beh OF ace_permutation_tb IS

  CONSTANT HOLD_TIME  : TIME    := 20 ns;
  CONSTANT TEST_COUNT : INTEGER := 6;

  TYPE TEST_RECORD IS RECORD
    s_i : ACE_STATE;
    s_o : ACE_STATE;
  END RECORD;

  TYPE TEST_RECORD_VECTOR IS ARRAY (0 TO TEST_COUNT - 1) OF TEST_RECORD;

  SIGNAL TEST_SETS : TEST_RECORD_VECTOR :=
  (
  (
  s_i => X"000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F2021222324252627",
  s_o => X"BAC2CFA09D50B393992DAC9E4C594FBC40E71861082DC747F243883A1BAC45DBA613831C7B12D7B3"
  ),
  (
  s_i => X"28292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F",
  s_o => X"A755D862E2A26809E5C43FF94D0B96AE6DA280078E16AF38F1ADC12F4F5CECCA8BBA57E296EC119B"
  ),
  (
  s_i => X"505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F7071727374757677",
  s_o => X"6AD3A7D500518AC2349E2DF65E9F71835891B07EBF51219739860F1FB5C2E695600057E653C37F97"
  ),
  (
  s_i => X"78797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9F",
  s_o => X"91F73FE2E3785F920306EE0EDE6DDE501EB484C50EA674004D242B898EB42E79D2E0186B0C6E9F3C"
  ),
  (
  s_i => X"A0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7",
  s_o => X"7553BACEB97218863F8476377CA571FADE8D513A9483FA878D2417F6C920608BC847A0679FEC5013"
  ),
  (
  s_i => X"C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEF",
  s_o => X"8067213F18A89C2E67FD48F8F84D73FBF43FF51D7ECA033DA4F692564BF013BA27412BF3EBF71F25"
  )
  );

  SIGNAL s_i  : ACE_STATE;
  SIGNAL step : UNSIGNED(ACE_STEP_CNT_WIDTH - 1 DOWNTO 0);
  SIGNAL s_o  : ACE_STATE;

  SIGNAL rscv : STD_LOGIC_VECTOR (RSC_ROM_O_SIZE - 1 DOWNTO 0);

  -- Use aliases to split up ROM output and use individual constants.
  ALIAS rc_0 : RSC IS rscv(
  (RSC_ROM_O_SIZE - 1) DOWNTO (RSC_ROM_O_SIZE - RSC_SIZE));

  ALIAS rc_1 : RSC IS rscv(
  (RSC_ROM_O_SIZE - RSC_SIZE - 1) DOWNTO (RSC_ROM_O_SIZE - 2 * RSC_SIZE));

  ALIAS rc_2 : RSC IS rscv(
  (RSC_ROM_O_SIZE - 2 * RSC_SIZE - 1) DOWNTO (RSC_ROM_O_SIZE - 3 * RSC_SIZE));

  ALIAS sc_0 : RSC IS rscv(
  (RSC_ROM_O_SIZE - 3 * RSC_SIZE - 1) DOWNTO (RSC_ROM_O_SIZE - 4 * RSC_SIZE));

  ALIAS sc_1 : RSC IS rscv(
  (RSC_ROM_O_SIZE - 4 * RSC_SIZE - 1) DOWNTO (RSC_ROM_O_SIZE - 5 * RSC_SIZE));

  ALIAS sc_2 : RSC IS rscv(
  (RSC_ROM_O_SIZE - 5 * RSC_SIZE - 1) DOWNTO (RSC_ROM_O_SIZE - 6 * RSC_SIZE));

BEGIN

  i_round_consts : ENTITY WORK.RSC_ROM(RSC_ROM_DF)
    PORT MAP(
      addr_i => STD_LOGIC_VECTOR(step),
      d_o    => rscv
    );

  ace_step : ENTITY WORK.ACE_STEP(ACE_STEP_DF)
    PORT MAP(
      s_i    => s_i,
      sc_0_i => sc_0,
      sc_1_i => sc_1,
      sc_2_i => sc_2,
      rc_0_i => rc_0,
      rc_1_i => rc_1,
      rc_2_i => rc_2,
      s_o    => s_o
    );

  -- Although is is basically the same as the ACE-step test, it helps because with
  -- this test I know that all entries in the ROM are correct.
  ace_permutation_tests : PROCESS
  BEGIN

    REPORT "ACE-permutation Tests" SEVERITY note;

    FOR i IN 0 TO TEST_COUNT - 1 LOOP
      REPORT "Running test " & INTEGER'image(i) SEVERITY note;

      step <= TO_UNSIGNED(0, step'length);
      s_i  <= TEST_SETS(i).s_i;
      FOR i IN 0 TO ACE_STEPS - 2 LOOP
        WAIT FOR HOLD_TIME;
        step <= step + 1;
        s_i  <= s_o;
      END LOOP;
      WAIT FOR HOLD_TIME;

      IF (s_o = TEST_SETS(i).s_o) THEN
        REPORT "Test " & INTEGER'image(i) & " PASSED." SEVERITY note;
      ELSE
        REPORT "Test " & INTEGER'image(i) & " FAILED." SEVERITY error;
      END IF;
    END LOOP;

  END PROCESS;
END ace_permutation_tb_beh;