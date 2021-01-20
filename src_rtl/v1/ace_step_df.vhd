------------------------------------------------------------------------------
---- Function ACE-step                                                    ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This is the architecture definition for the ACE-step function.       ----
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

ARCHITECTURE ace_step_df OF ace_step IS

  ------------------------------- Input aliases ------------------------------
  -- Input state words
  ALIAS s_i_word_a : WORD IS s_i(STATE_WORD_A_RANGE);
  ALIAS s_i_word_b : WORD IS s_i(STATE_WORD_B_RANGE);
  ALIAS s_i_word_c : WORD IS s_i(STATE_WORD_C_RANGE);
  ALIAS s_i_word_d : WORD IS s_i(STATE_WORD_D_RANGE);
  ALIAS s_i_word_e : WORD IS s_i(STATE_WORD_E_RANGE);

  --------------------- Intermidiary signals and aliases ---------------------
  -- Constant vector of 56 '1's to be appended with SCs
  SIGNAL const_56_ones : STD_LOGIC_VECTOR (WORD_SIZE - RSC_SIZE - 1 DOWNTO 0);

  -- SB-64 outputs
  SIGNAL sba_res : WORD;
  SIGNAL sbc_res : WORD;
  SIGNAL sbe_res : WORD;

  -- Next state words
  SIGNAL a_n : WORD;
  SIGNAL d_n : WORD;
  SIGNAL e_n : WORD;
  ALIAS b_n  : WORD IS sbc_res;
  ALIAS c_n  : WORD IS sba_res;

BEGIN

  const_56_ones <= (OTHERS => '1');

  sb64_a : ENTITY work.sb64(sb64_df)
    PORT MAP(
      x_i  => s_i_word_a,
      rc_i => rc_0_i,
      x_o  => sba_res
    );

  sb64_c : ENTITY work.sb64(sb64_df)
    PORT MAP(
      x_i  => s_i_word_c,
      rc_i => rc_1_i,
      x_o  => sbc_res
    );

  sb64_e : ENTITY work.sb64(sb64_df)
    PORT MAP(
      x_i  => s_i_word_e,
      rc_i => rc_2_i,
      x_o  => sbe_res
    );

  e_n <= s_i_word_b XOR sbc_res XOR (const_56_ones & sc_0_i);
  a_n <= s_i_word_d XOR sbe_res XOR (const_56_ones & sc_1_i);
  d_n <=    sbe_res XOR sba_res XOR (const_56_ones & sc_2_i);

  s_o <= a_n & b_n & c_n & d_n & e_n;

END ace_step_df;