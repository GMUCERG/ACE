------------------------------------------------------------------------------
---- Round and step constants ROM                                         ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This is the architecture definition for the round and step constants ----
---- read-only memory. Used in the ACE-step function.                     ----
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

ARCHITECTURE rsc_rom_df OF rsc_rom IS
  TYPE rsc_array IS ARRAY (0 TO ACE_STEPS - 1)
  OF STD_LOGIC_VECTOR(RSC_ROM_O_SIZE - 1 DOWNTO 0);

  -- Each value is equal to rc_0i || rc_1i || rc_2i || sc_0i || sc_1i || sc_2i
  -- where i is the step index. Underscores used for clarity.
  CONSTANT rsc_rom_contents : rsc_array := (
    X"07_53_43_50_28_14",
    X"0a_5d_e4_5c_ae_57",
    X"9b_49_5e_91_48_24",
    X"e0_7f_cc_8d_c6_63",
    X"d1_be_32_53_a9_54",
    X"1a_1d_4e_60_30_18",
    X"22_28_75_68_34_9a",
    X"f7_6c_25_e1_70_38",
    X"62_82_fd_f6_7b_bd",
    X"96_47_f9_9d_ce_67",
    X"71_6b_76_40_20_10",
    X"aa_88_a0_4f_27_13",
    X"2b_dc_b0_be_5f_2f",
    X"e9_8b_09_5b_ad_d6",
    X"cf_59_1e_e9_74_ba",
    X"b7_c6_ad_7f_3f_1f"
  );
BEGIN
  d_o <= rsc_rom_contents(to_integer(unsigned(addr_i)));
END rsc_rom_df;