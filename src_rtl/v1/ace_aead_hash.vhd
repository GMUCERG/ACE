------------------------------------------------------------------------------
---- CryptoCore for ACE-AEAD-128 and ACE-HASH-256                         ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This is the CryptoCore entity definition, used in the LWC            ----
---- Development Package.                                                 ----
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
---- This program is distributed IN the hope that it will be useful,      ----
---- but WITHOUT ANY WARRANTY; without even the implied warranty of       ----
---- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        ----
---- GNU General Public License for more details.                         ----
----                                                                      ----
---- You should have received a copy of the GNU General Public License    ----
---- along with this program. If not, see <http://www.gnu.org/licenses/>. ----
----                                                                      ----
------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;
USE WORK.DESIGN_PKG.ALL;

ENTITY CryptoCore IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        --PreProcessor===============================================
        ----!key----------------------------------------------------
        key       : IN STD_LOGIC_VECTOR (CCSW - 1 DOWNTO 0);
        key_valid : IN STD_LOGIC;
        key_ready : OUT STD_LOGIC;
        ----!Data----------------------------------------------------
        bdi             : IN STD_LOGIC_VECTOR (CCW - 1 DOWNTO 0);
        bdi_valid       : IN STD_LOGIC;
        bdi_ready       : OUT STD_LOGIC;
        bdi_pad_loc     : IN STD_LOGIC_VECTOR (CCWdiv8 - 1 DOWNTO 0);
        bdi_valid_bytes : IN STD_LOGIC_VECTOR (CCWdiv8 - 1 DOWNTO 0);
        bdi_size        : IN STD_LOGIC_VECTOR (3 - 1 DOWNTO 0);
        bdi_eot         : IN STD_LOGIC;
        bdi_eoi         : IN STD_LOGIC;
        bdi_type        : IN STD_LOGIC_VECTOR (4 - 1 DOWNTO 0);
        decrypt_in      : IN STD_LOGIC;
        key_update      : IN STD_LOGIC;
        hash_in         : IN STD_LOGIC;
        --!Post Processor=========================================
        bdo             : OUT STD_LOGIC_VECTOR (CCW - 1 DOWNTO 0);
        bdo_valid       : OUT STD_LOGIC;
        bdo_ready       : IN STD_LOGIC;
        bdo_type        : OUT STD_LOGIC_VECTOR (4 - 1 DOWNTO 0);
        bdo_valid_bytes : OUT STD_LOGIC_VECTOR (CCWdiv8 - 1 DOWNTO 0);
        end_of_block    : OUT STD_LOGIC;
        msg_auth_valid  : OUT STD_LOGIC;
        msg_auth_ready  : IN STD_LOGIC;
        msg_auth        : OUT STD_LOGIC
    );
END CryptoCore;