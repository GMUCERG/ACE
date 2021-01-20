------------------------------------------------------------------------------
---- Teastbench for ace_step entity.                                      ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This testbench uses the ace_step and rsc_rom entities to execute     ----
---- and test ACE-steps.                                                  ----
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

ENTITY ace_step_tb IS
END ace_step_tb;

ARCHITECTURE ace_step_tb_beh OF ace_step_tb IS

  CONSTANT HOLD_TIME  : TIME    := 100 ns;
  CONSTANT TEST_COUNT : INTEGER := 4;

  TYPE TEST_RECORD IS RECORD
    step : STD_LOGIC_VECTOR(ACE_STEP_CNT_WIDTH - 1 DOWNTO 0);
    s_i  : ACE_STATE;
    s_o  : ACE_STATE;
  END RECORD;

  TYPE TEST_RECORD_VECTOR IS ARRAY (0 TO TEST_COUNT - 1) OF TEST_RECORD;

  SIGNAL TEST_SETS : TEST_RECORD_VECTOR :=
  (
  (
  step => "0000",
  s_i  => X"000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F2021222324252627",
  s_o  => X"24F410111DA8C5A72A25569CEC38ECCA28B62AF3100F6727145B20F911BABCA3DDD3A3681FCA1D95"
  ),
  (
  step => "0001",
  s_i  => X"28292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F",
  s_o  => X"CE9A15A22D16DF31ED3BDC6E90345552D60BC9119B57594958D09EF0F204C0C622F511A25BFE9C39"
  ),
  (
  step => "0010",
  s_i  => X"505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F7071727374757677",
  s_o  => X"A39BA41E4A4640381353058DCCB6394DFB277F762358DDE930D5B1030573F3D2B4F5A0296F149883"
  ),
  (
  step => "0011",
  s_i  => X"78797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9F",
  s_o  => X"1B4CFF3D5EA8761FE8DB50D0D9A3A10F34FE7AC205C74952BF23176CCFFAA97F97A52DACA2D9D805"
  )
  );

  SIGNAL s_i  : ACE_STATE;
  SIGNAL step : STD_LOGIC_VECTOR(ACE_STEP_CNT_WIDTH - 1 DOWNTO 0);
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
      addr_i => step,
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

  ace_step_tests : PROCESS
  BEGIN

    REPORT "ACE-step Tests" SEVERITY note;

    FOR i IN 0 TO TEST_COUNT - 1 LOOP
      REPORT "Running test " & INTEGER'image(i) SEVERITY note;

      s_i  <= TEST_SETS(i).s_i;
      step <= TEST_SETS(i).step;
      WAIT FOR HOLD_TIME / 2;

      IF (s_o = TEST_SETS(i).s_o) THEN
        REPORT "Test " & INTEGER'image(i) & " PASSED." SEVERITY note;
      ELSE
        REPORT "Test " & INTEGER'image(i) & " FAILED." SEVERITY error;
      END IF;
      WAIT FOR HOLD_TIME / 2;
    END LOOP;

  END PROCESS;
END ace_step_tb_beh;