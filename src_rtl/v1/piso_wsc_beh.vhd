------------------------------------------------------------------------------
---- Generic Parallel In Serial Out shift register.                       ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This is the architecture definition for a PISO with generic word     ----
---- size and count.                                                      ----
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

ARCHITECTURE piso_wsc_beh OF piso_wsc IS

  SIGNAL piso : STD_LOGIC_VECTOR(WORD_COUNT * WORD_SIZE - 1 DOWNTO 0);

BEGIN

  data_o <= piso(WORD_SIZE - 1 DOWNTO 0);

  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (en = '1') THEN
        IF (ld = '1') THEN
          piso <= data_i;
        ELSE
          piso <= data_i(WORD_COUNT * WORD_SIZE - 1 DOWNTO (WORD_COUNT - 1) * WORD_SIZE) & 
          piso(WORD_COUNT * WORD_SIZE - 1 DOWNTO WORD_SIZE);
        END IF;
      END IF;
    END IF;
  END PROCESS;

END piso_wsc_beh;
