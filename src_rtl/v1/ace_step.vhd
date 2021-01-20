------------------------------------------------------------------------------
---- Function ACE-step                                                    ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This is the entity definition for the ACE-step function, used in the ----
---- ACE-permutation function.                                            ----
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

ENTITY ace_step IS
  PORT (
    -- Input and output states.
    s_i    : IN ACE_STATE_V;
    s_o    : OUT ACE_STATE_V;
    -- Step constants
    sc_0_i : IN RSC;
    sc_1_i : IN RSC;
    sc_2_i : IN RSC;
    -- Round constants
    rc_0_i : IN RSC;
    rc_1_i : IN RSC;
    rc_2_i : IN RSC
  );
END ace_step;