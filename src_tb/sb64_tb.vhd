------------------------------------------------------------------------------
---- Teastbench for SB64 entity.                                         ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This testbench uses the sb64 entity to execute and test SB-64.       ----
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

ENTITY sb_64_tb IS
END sb_64_tb;

ARCHITECTURE sb_64_tb_beh OF sb_64_tb IS

  CONSTANT HOLD_TIME  : TIME    := 100 ns;
  CONSTANT TEST_COUNT : INTEGER := 5;

  TYPE TEST_RECORD IS RECORD
    x_i : WORD;
    c_i : STD_LOGIC_VECTOR(RSC_SIZE - 1 DOWNTO 0);
    x_o : WORD;
  END RECORD;

  TYPE TEST_RECORD_VECTOR IS ARRAY (0 TO TEST_COUNT - 1) OF TEST_RECORD;

  CONSTANT TEST_SETS : TEST_RECORD_VECTOR :=
  (
  (x_i => X"0000000000000000", c_i => X"00", x_o => X"00C70B2A004393B7"),
  (x_i => X"0001020304050607", c_i => X"07", x_o => X"28B62AF3100F6727"),
  (x_i => X"08090A0B0C0D0E0F", c_i => X"0A", x_o => X"F6BDEABFC71BE560"),
  (x_i => X"1011121314151617", c_i => X"9B", x_o => X"2A254A40EC38E4A2"),
  (x_i => X"18191A1B1C1D1E1F", c_i => X"E0", x_o => X"1F98508032130667")
  );

  SIGNAL x_i : WORD;
  SIGNAL c_i : STD_LOGIC_VECTOR(RSC_SIZE - 1 DOWNTO 0);
  SIGNAL x_o : WORD;

BEGIN

  sb64 : ENTITY WORK.SB64(SB64_DF)
    PORT MAP(
      x_i  => x_i,
      rc_i => c_i,
      x_o  => x_o
    );

  
  sb64_tests : PROCESS
  BEGIN

    REPORT "SB64 Tests" SEVERITY note;
  
    FOR i IN 0 TO TEST_COUNT - 1 LOOP
      REPORT "Running test " & INTEGER'image(i) SEVERITY note;

      x_i <= TEST_SETS(i).x_i;
      c_i <= TEST_SETS(i).c_i;
      WAIT FOR HOLD_TIME / 2;

      IF (x_o = TEST_SETS(i).x_o) THEN
        REPORT "Test " & INTEGER'image(i) & " PASSED." SEVERITY note;
      ELSE
        REPORT "Test " & INTEGER'image(i) & " FAILED." SEVERITY error;
      END IF;
      WAIT FOR HOLD_TIME / 2;
    END LOOP;

  END PROCESS;
END sb_64_tb_beh;