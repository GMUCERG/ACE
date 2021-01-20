------------------------------------------------------------------------------
---- Round and step cosntants ROM                                         ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This is the entity definition for the round and step constants ----
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
USE WORK.DESIGN_PKG.ALL;

ENTITY rsc_rom IS
  PORT (
    addr_i : IN STD_LOGIC_VECTOR (ACE_STEP_CNT_WIDTH - 1 DOWNTO 0);
    d_o    : OUT STD_LOGIC_VECTOR (RSC_ROM_O_SIZE - 1 DOWNTO 0));
END rsc_rom;