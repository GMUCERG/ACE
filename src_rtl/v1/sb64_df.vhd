------------------------------------------------------------------------------
---- Function SB-64                                                       ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This is the architecture definition for the SB-64 function, used in  ----
---- then ACE-step function.                                              ----
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
USE WORK.DESIGN_PKG.ALL;

ARCHITECTURE sb64_df OF sb64 IS

  TYPE SB64_VECTOR IS ARRAY (0 TO SB64_ROUNDS + 2 - 1) OF HALF_WORD;

  --------------------- Intermidiary signals and aliases ---------------------
  -- Intermidiaries for SB-64 rounds
  SIGNAL v_x         : SB64_VECTOR;
  SIGNAL v_x_jm1_rl5 : SB64_VECTOR;
  SIGNAL v_x_jm1_rl1 : SB64_VECTOR;
  SIGNAL v_f501      : SB64_VECTOR;

  -- Constant vector of 31  '1's to be appended with RCs
  SIGNAL const_31_ones : STD_LOGIC_VECTOR (HALF_WORD_SIZE - 1 - 1 DOWNTO 0);

BEGIN

  const_31_ones <= (OTHERS => '1');

  -- Positions 0 and 1 are used by the initial input vector halfs.
  v_x(1) <= x_i(WORD_SIZE - 1 DOWNTO HALF_WORD_SIZE);
  v_x(0) <= x_i(HALF_WORD_SIZE - 1 DOWNTO 0);

  -- Generate SB64_ROUNDS number of SB64 rounds. Loop is offset by 2.
  -- The position of intermidiary signals (eg. v_f501) is not important,
  -- but it is matched to the notation used in the function for clarity.
  sb64_rounds_gen :
  FOR j IN 2 TO (SB64_ROUNDS + 2 - 1) GENERATE

    -- Rotate v_x(j - 1) left by 5
    v_x_jm1_rl5(j - 1) <= v_x(j - 1)(HALF_WORD_SIZE - 6 DOWNTO 0)
    & v_x(j - 1)(HALF_WORD_SIZE - 1 DOWNTO HALF_WORD_SIZE - 5);

    -- Rotate v_x(j - 1) left by 1
    v_x_jm1_rl1(j - 1) <= v_x(j - 1)(HALF_WORD_SIZE - 2 DOWNTO 0)
    & v_x(j - 1)(HALF_WORD_SIZE - 1);

    -- Assign f(5,0,1)(j - 1)
    v_f501(j - 1) <= (v_x_jm1_rl5(j - 1) AND v_x(j - 1))
    XOR v_x_jm1_rl1(j - 1);

    v_x(j) <= v_f501(j - 1) XOR v_x(j - 2) XOR (const_31_ones & rc_i(j - 2));

  END GENERATE;

  x_o <= v_x(SB64_ROUNDS + 2 - 1) & v_x(SB64_ROUNDS + 2 - 2);

END sb64_df;