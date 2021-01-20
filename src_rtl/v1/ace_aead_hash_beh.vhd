------------------------------------------------------------------------------
---- CryptoCore for ACE-AEAD-128 and ACE-HASH-256                         ----
----                                                                      ----
---- This file is a part of the LWC ACE AEAD and Hash Project.            ----
----                                                                      ----
---- Description:                                                         ----
---- This is the CryptoCore architecture definition, used in the LWC      ----
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
USE WORK.NIST_LWAPI_pkg.ALL;

ARCHITECTURE behavioral OF CryptoCore IS

  ------------------------------- ASM state items ------------------------------
  TYPE ASM_STATE IS (
    IDLE, -- Idle, doing nothing.

    STORE_KEY,  -- Store key into key SIPO register
    STORE_NPUB, -- Store NPub into NPub/tag SIPO register
    STORE_TAG,  -- Store tag into NPub/tag SIPO register

    AEAD_INIT_LD,    -- AEAD initialization load
    AEAD_INIT_LD_AP, -- AEAD initialization load ACE-permutation
    AEAD_INIT_K0_AP, -- AEAD initialization K0 absorb ACE-permutation
    AEAD_INIT_K1_AP, -- AEAD initialization K1 absorb ACE-permutation
    HASH_INIT_LD,    -- Hash initialization load 
    HASH_INIT_LD_AP, -- Hash initialization load ACE-permutation

    AEAD_ABSORB_AD,  -- Read AEAD AD and absorb into Sr
    AEAD_ABSORB_MSG, -- Read AEAD msg and absorb into Sr, and also output to bdo
    HASH_ABSORB_MSG, -- Read hash msg and absorb into Sr

    AEAD_AD_AP,      -- AEAD AD absorb ACE-permutation
    AEAD_MSG_AP,     -- AEAD message absorb ACE-permutation
    HASH_MSG_AP,     -- Hash message absorb ACE-permutation
    AEAD_AD_PAD_AP,  -- AEAD AD whole padding block ACE-permutation
    AEAD_MSG_PAD_AP, -- AEAD message whole padding block ACE-permutation
    HASH_MSG_PAD_AP, -- Hash whole padding block ACE-permutation

    AEAD_FIN_K0_AP, -- AEAD finalizaion K0 absorb ACE-permutation
    AEAD_FIN_K1_AP, -- AEAD finalizaion K1 absorb ACE-permutation
    HASH_SQZ_AP,    -- Hash squeeze ACE-permutation

    EXTRACT_HASH_VAL, -- Output hash value
    EXTRACT_TAG,      -- Output tag value
    VERIFY_TAG       -- Verify tag matches
  );

  SIGNAL state   : ASM_STATE; -- Current ASM state
  SIGNAL n_state : ASM_STATE; -- Next ASM state

  ----------------------- ACE state signals and aliases ------------------------
  -- Data
  -- Initialization vectors for hashing and AEAD
  SIGNAL ld_hash_v : ACE_STATE_V;
  SIGNAL ld_aead_v : ACE_STATE_V;

  -- Ace state register.
  SIGNAL ace_state : ACE_STATE_V; -- Whole state
  SIGNAL ace_sr    : ACE_SR_V;    -- Sr portion
  SIGNAL ace_sc    : ACE_SC_V;    -- Sc portion

  -- Control
  SIGNAL ace_state_en : STD_LOGIC;

  --------------------- Next ACE state signals and aliases ---------------------
  -- Data
  -- Next ACE state signal
  SIGNAL n_ace_state : ACE_STATE_V; -- Whole state
  SIGNAL n_ace_sr    : ACE_SR_V;    -- Sr portion
  SIGNAL sc_ds       : ACE_SC_V;    -- Sc xor'd with domain separator
  SIGNAL n_ace_sc    : ACE_SC_V;    -- Sc portion

  -- ACE-step results
  SIGNAL ace_step_out     : ACE_STATE_V; -- Whole state
  SIGNAL ace_step_out_tag : DOUBLE_WORD; -- Tag portion
  SIGNAL ace_step_out_sr  : ACE_SR_V;    -- Sr portion
  SIGNAL ace_step_out_sc  : ACE_SC_V;    -- Sc portion
  SIGNAL sco_ds           : ACE_SC_V;    -- Sc out xor'd with domain separator

  -- Control

  -- Next Sr portion mux select
  SIGNAL srn_sel : STD_LOGIC_VECTOR(2 DOWNTO 0);
  -- Next Sc portion mux select
  SIGNAL scn_sel : STD_LOGIC_VECTOR(1 DOWNTO 0);
  -- Domain separator bits to XOR with Sc portion
  SIGNAL ds_bits : STD_LOGIC_VECTOR(1 DOWNTO 0);

  -- Next Sr portion mux select constants
  CONSTANT SRN_SEL_SRO     : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
  CONSTANT SRN_SEL_BDI     : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
  CONSTANT SRN_SEL_LD_HASH : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
  CONSTANT SRN_SEL_LD_AEAD : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
  CONSTANT SRN_SEL_SRO_PAD : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
  CONSTANT SRN_SEL_SRO_K0  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";
  CONSTANT SRN_SEL_SRO_K1  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
  CONSTANT SRN_SEL_SR_BDI  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";

  -- Next Sc portion mux select constants
  CONSTANT SCN_SEL_SCO_DS  : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
  CONSTANT SCN_SEL_SC_DS   : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
  CONSTANT SCN_SEL_LD_HASH : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
  CONSTANT SCN_SEL_LD_AEAD : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";

  --------------------------- Key signals and aliases --------------------------
  -- Data
  SIGNAL k_sipo_out : DOUBLE_WORD;
  SIGNAL k          : DOUBLE_WORD;

  ALIAS k1 : WORD IS k(DW_W1_RANGE); -- K1 word
  ALIAS k0 : WORD IS k(DW_W0_RANGE); -- K0 word

  -- Control
  SIGNAL si_key : STD_LOGIC; -- Key SIPO enable

  ----------------------- Nonce/Tag signals and aliases  -----------------------
  -- Data
  SIGNAL nt_sipo_out : DOUBLE_WORD;
  SIGNAL nt          : DOUBLE_WORD;

  ALIAS nt1 : WORD IS nt(DW_W1_RANGE); -- N1/T1 word
  ALIAS nt0 : WORD IS nt(DW_W0_RANGE); -- N0/T0 word

  -- Control
  SIGNAL si_nt : STD_LOGIC; -- npub/tag SIPO enable

  -------------------------- bdi signals and aliases  --------------------------
  -- Data
  SIGNAL bdi_padd : HALF_WORD; -- padded bdi half word
  SIGNAL bdi_buf  : HALF_WORD; -- previous passed bdi half word
  SIGNAL bdi_lhw  : HALF_WORD; -- bdi low half word, padding-needs dependant
  SIGNAL bdi_64_p : WORD;      -- padded bdi word

  -- Control
  SIGNAL en_bdi_buf : STD_LOGIC; -- bdi half word buffer
  SIGNAL bdi_sel    : STD_LOGIC; -- padded bdi half word or padding half word

  -------------------------- bdo signals and aliases  --------------------------
  -- Data
  SIGNAL tag_piso_hw  : HALF_WORD; -- Tag portion half word
  SIGNAL hash_piso_hw : HALF_WORD; -- Hash portion half word

  -- Control
  SIGNAL ld_tag_piso  : STD_LOGIC; -- tag PISO load
  SIGNAL en_tag_piso  : STD_LOGIC; -- tag PISO enable
  SIGNAL ld_hash_piso : STD_LOGIC; -- tag PISO load
  SIGNAL en_hash_piso : STD_LOGIC; -- tag PISO enable

  SIGNAL bdo_sel : STD_LOGIC_VECTOR(1 DOWNTO 0); -- bdo mux select 

  -- bdo mux select constants
  CONSTANT BDO_SEL_MSG0 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
  CONSTANT BDO_SEL_MSG1 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
  CONSTANT BDO_SEL_TAG  : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
  CONSTANT BDO_SEL_HASH : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";

  ------------------------------ Counter signals -------------------------------
  -- Data
  -- Counter for ACE-permutation's ACE-step number
  SIGNAL ace_step_cnt   : UNSIGNED(ACE_STEP_CNT_WIDTH - 1 DOWNTO 0);
  SIGNAL n_ace_step_cnt : UNSIGNED(ACE_STEP_CNT_WIDTH - 1 DOWNTO 0);
  -- Counter for half words shifted into key and npub/tag SIPOs
  SIGNAL half_word_cnt   : UNSIGNED(KNT_HW_CNT_WIDTH - 1 DOWNTO 0);
  SIGNAL n_half_word_cnt : UNSIGNED(KNT_HW_CNT_WIDTH - 1 DOWNTO 0);
  -- Counter for number of hash squeezes completed
  SIGNAL hash_sqz_cnt   : UNSIGNED(HASH_SQZ_CNT_WIDTH - 1 DOWNTO 0);
  SIGNAL n_hash_sqz_cnt : UNSIGNED(HASH_SQZ_CNT_WIDTH - 1 DOWNTO 0);

  -------------------------- ROM signals and aliases ---------------------------
  -- Data
  SIGNAL rscv : STD_LOGIC_VECTOR (RSC_ROM_O_SIZE - 1 DOWNTO 0);

  -- Use aliases to split up ROM output into three rc and three sc constants.
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

  -- Internal Port signals
  SIGNAL key_ready_s       : STD_LOGIC;
  SIGNAL bdi_ready_s       : STD_LOGIC;
  SIGNAL bdi_valid_bytes_s : STD_LOGIC_VECTOR(CCWdiv8 - 1 DOWNTO 0);
  SIGNAL bdi_pad_loc_s     : STD_LOGIC_VECTOR(CCWdiv8 - 1 DOWNTO 0);

  SIGNAL bdo_valid_bytes_s : STD_LOGIC_VECTOR(CCWdiv8 - 1 DOWNTO 0);
  SIGNAL bdo_valid_s       : STD_LOGIC;
  SIGNAL bdo_type_s        : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL end_of_block_s    : STD_LOGIC;
  SIGNAL msg_auth_valid_s  : STD_LOGIC;

  -- Internal flags
  SIGNAL bdi_partial_s    : STD_LOGIC;
  SIGNAL n_decrypt_s      : STD_LOGIC;
  SIGNAL decrypt_s        : STD_LOGIC;
  SIGNAL n_hash_s         : STD_LOGIC;
  SIGNAL hash_s           : STD_LOGIC;
  SIGNAL n_empty_hash_s   : STD_LOGIC;
  SIGNAL empty_hash_s     : STD_LOGIC;
  SIGNAL n_msg_auth_s     : STD_LOGIC;
  SIGNAL msg_auth_s       : STD_LOGIC;
  SIGNAL n_update_key_s   : STD_LOGIC;
  SIGNAL update_key_s     : STD_LOGIC;
  SIGNAL end_of_type_s    : STD_LOGIC;
  SIGNAL n_end_of_type_s  : STD_LOGIC;
  SIGNAL end_of_input_s   : STD_LOGIC;
  SIGNAL n_end_of_input_s : STD_LOGIC;
  SIGNAL add_pad_word_s   : STD_LOGIC;
  SIGNAL n_add_pad_word_s : STD_LOGIC;
  SIGNAL prev_hw_full_s   : STD_LOGIC;
  SIGNAL n_prev_hw_full_s : STD_LOGIC;
BEGIN

  -------------------------- Internal IO assignments ---------------------------
  bdi_valid_bytes_s <= bdi_valid_bytes;
  bdi_pad_loc_s     <= bdi_pad_loc;
  key_ready         <= key_ready_s;
  bdi_ready         <= bdi_ready_s;
  bdo_valid_bytes   <= bdo_valid_bytes_s;
  bdo_valid         <= bdo_valid_s;
  bdo_type          <= bdo_type_s;
  end_of_block      <= end_of_block_s;
  msg_auth          <= msg_auth_s;
  msg_auth_valid    <= msg_auth_valid_s;

  ----------------------------- Register processes -----------------------------

  -- ACE state register
  p_ace_state_reg : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (rst = '1') THEN
        ace_state <= (OTHERS => '0');
        bdi_buf   <= (OTHERS => '0');
      ELSE
        IF (ace_state_en = '1') THEN
          ace_state <= n_ace_state;
        END IF;
        IF (en_bdi_buf = '1') THEN
          bdi_buf <= bdi_padd;
        END IF;
      END IF;
    END IF;
  END PROCESS p_ace_state_reg;

  -- FSM state and indicator/flag registers
  p_ctrl_regs : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (rst = '1') THEN
        -- Reset state
        state <= IDLE;

        -- Reset input indicators
        update_key_s   <= '0';
        decrypt_s      <= '0';
        hash_s         <= '0';
        empty_hash_s   <= '0';
        end_of_type_s  <= '0';
        end_of_input_s <= '0';

        -- Reset output indicators
        msg_auth_s <= '0';
      ELSE
        -- Set next state
        state <= n_state;

        -- Set next input indicators
        update_key_s   <= n_update_key_s;
        decrypt_s      <= n_decrypt_s;
        hash_s         <= n_hash_s;
        empty_hash_s   <= n_empty_hash_s;
        end_of_type_s  <= n_end_of_type_s;
        end_of_input_s <= n_end_of_input_s;
        add_pad_word_s <= n_add_pad_word_s;
        prev_hw_full_s <= n_prev_hw_full_s;

        -- Set next output indicators
        msg_auth_s <= n_msg_auth_s;
      END IF;
    END IF;
  END PROCESS p_ctrl_regs;

  -- Counter registers
  p_cnt_regs : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (rst = '1') THEN
        -- Reset counters
        ace_step_cnt  <= to_unsigned(0, ace_step_cnt'length);
        half_word_cnt <= to_unsigned(0, half_word_cnt'length);
        hash_sqz_cnt  <= to_unsigned(0, hash_sqz_cnt'length);
      ELSE
        -- Set next counters
        ace_step_cnt  <= n_ace_step_cnt;
        half_word_cnt <= n_half_word_cnt;
        hash_sqz_cnt  <= n_hash_sqz_cnt;
      END IF;
    END IF;
  END PROCESS p_cnt_regs;

  --------------------------------- FSM process --------------------------------
  p_next_state : PROCESS (
    state,
    key_valid, key_update,
    bdi_valid, bdi_type, end_of_input_s, end_of_type_s, hash_in, decrypt_s,
    msg_auth_valid_s, msg_auth_ready,
    half_word_cnt, ace_step_cnt, hash_sqz_cnt, add_pad_word_s)
  BEGIN
    -- Set the next state to the current state by default.
    n_state <= state;

    CASE state IS
        -- Leave from idle state into initializing hashing, storing NPub,
        -- or storing key.
      WHEN IDLE =>
        IF (bdi_valid = '1') THEN
          IF (hash_in = '1' AND bdi_type = HDR_HASH_MSG) THEN
            n_state <= HASH_INIT_LD;
          ELSIF (bdi_type = HDR_NPUB) THEN
            n_state <= STORE_NPUB;
          END IF;
        ELSIF (key_valid = '1' AND key_update = '1') THEN
          n_state <= STORE_KEY;
        ELSE
          n_state <= IDLE;
        END IF;

        -- Store key half words while key register is not full then go to
        -- storing NPub or to idle.
      WHEN STORE_KEY =>
        IF (half_word_cnt >= KEY_HALF_WORDS - 1) THEN
          IF (bdi_type = HDR_NPUB) THEN
            n_state <= STORE_NPUB;
          ELSE
            n_state <= IDLE;
          END IF;
        ELSE
          n_state <= STORE_KEY;
        END IF;

        -- Store NPub half words while NPub register is not full then go to
        -- loading the state for encryption or decryption.
      WHEN STORE_NPUB =>
        IF (half_word_cnt >= NPUB_HALF_WORDS - 1) THEN
          n_state <= AEAD_INIT_LD;
        ELSE
          n_state <= STORE_NPUB;
        END IF;

        -- Store tag half words while tag register is not full then go to
        -- verify tag.
      WHEN STORE_TAG =>
        IF (half_word_cnt >= TAG_HALF_WORDS - 1) THEN
          n_state <= VERIFY_TAG;
        ELSE
          n_state <= STORE_TAG;
        END IF;

        -- Load the ACE state with initial vector for encryption or decryption
        -- then go to the initialization ace permutation
      WHEN AEAD_INIT_LD =>
        n_state <= AEAD_INIT_LD_AP;

        -- Stay in AEAD initialization load ACE-permutation until 16 ACE-steps
        -- have been completed. After, absorb K0 and do ACE-permutation.
      WHEN AEAD_INIT_LD_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          n_state <= AEAD_INIT_K0_AP;
        ELSE
          n_state <= AEAD_INIT_LD_AP;
        END IF;

        -- Stay in AEAD initialization K0 ACE-permutation until 16 ACE-steps
        -- have been completed. After, absorb K1 and do ACE-permutation.
      WHEN AEAD_INIT_K0_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          n_state <= AEAD_INIT_K1_AP;
        ELSE
          n_state <= AEAD_INIT_K0_AP;
        END IF;

        -- Stay in AEAD initialization K1 ACE-permutation until 16 ACE-steps
        -- have been completed. After, absorb AD or PT/CT.
      WHEN AEAD_INIT_K1_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_input_s = '1') THEN
            n_state <= AEAD_MSG_PAD_AP;
          ELSE
            IF (bdi_type = HDR_AD) THEN
              n_state <= AEAD_ABSORB_AD;
            ELSE
              n_state <= AEAD_ABSORB_MSG;
            END IF;
          END IF;
        ELSE
          n_state <= AEAD_INIT_K1_AP;
        END IF;

        -- Load the ACE state with initial vector for hashing
        -- then go to the initialization ace permutation
      WHEN HASH_INIT_LD =>
        n_state <= HASH_INIT_LD_AP;

        -- Stay in hash initialization load ACE-permutation until 16 ACE-steps
        -- have been completed. After, absorb K0 and do ACE-permutation. After,
        -- absorb hash MSG.
      WHEN HASH_INIT_LD_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_input_s = '1') THEN
            n_state <= HASH_MSG_PAD_AP;
          ELSE
            n_state <= HASH_ABSORB_MSG;
          END IF;
        ELSE
          n_state <= HASH_INIT_LD_AP;
        END IF;

        -- Read in AD and absorb into Sr portion, then go to AD ACE-permutation
      WHEN AEAD_ABSORB_AD =>
        IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
          n_state <= AEAD_AD_AP;
        ELSE
          n_state <= AEAD_ABSORB_AD;
        END IF;

        -- Read in PT/CT, absorb into Sr portion, and output, then go to PT/CT
        -- ACE-permutation
      WHEN AEAD_ABSORB_MSG =>
        IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
          n_state <= AEAD_MSG_AP;
        ELSE
          n_state <= AEAD_ABSORB_MSG;
        END IF;

        -- Read in hash msg and absorb into Sr portion, then go to hash msg
        -- ACE-permutation
      WHEN HASH_ABSORB_MSG =>
        IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
          n_state <= HASH_MSG_AP;
        ELSE
          n_state <= HASH_ABSORB_MSG;
        END IF;

        -- Stay in AD ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to absorb some message.
      WHEN AEAD_AD_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_type_s = '1') THEN
            IF (add_pad_word_s = '1') THEN
              n_state <= AEAD_AD_PAD_AP;
            ELSE
              IF (end_of_input_s = '1') THEN
                n_state <= AEAD_MSG_PAD_AP;
              ELSE
                n_state <= AEAD_ABSORB_MSG;
              END IF;
            END IF;
          ELSE
            n_state <= AEAD_ABSORB_AD;
          END IF;
        ELSE
          n_state <= AEAD_AD_AP;
        END IF;

        -- Stay in PT/CT ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to absorb PT/CT or finilize.
      WHEN AEAD_MSG_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_type_s = '1' OR end_of_input_s = '1') THEN
            IF (add_pad_word_s = '1') THEN
              n_state <= AEAD_MSG_PAD_AP;
            ELSE
              n_state <= AEAD_FIN_K0_AP;
            END IF;
          ELSE
            n_state <= AEAD_ABSORB_MSG;
          END IF;
        ELSE
          n_state <= AEAD_MSG_AP;
        END IF;

        -- Stay in hash msg ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to absorb hash msg or extract hash.
      WHEN HASH_MSG_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_type_s = '1' OR end_of_input_s = '1') THEN
            IF (add_pad_word_s = '1') THEN
              n_state <= HASH_MSG_PAD_AP;
            ELSE
              n_state <= EXTRACT_HASH_VAL;
            END IF;
          ELSE
            n_state <= HASH_ABSORB_MSG;
          END IF;
        ELSE
          n_state <= HASH_MSG_AP;
        END IF;

        -- Stay in AD pad block ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to absorb PT/CT or pad permutation.
      WHEN AEAD_AD_PAD_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_input_s = '1') THEN
            n_state <= AEAD_MSG_PAD_AP;
          ELSE
            n_state <= AEAD_ABSORB_MSG;
          END IF;
        ELSE
          n_state <= AEAD_AD_PAD_AP;
        END IF;

        -- Stay in AD pad block ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to absorb PT/CT or pad permutation.
      WHEN AEAD_MSG_PAD_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          n_state <= AEAD_FIN_K0_AP;
        ELSE
          n_state <= AEAD_MSG_PAD_AP;
        END IF;

        -- Stay in hash msg pad block ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to extract hash value.
      WHEN HASH_MSG_PAD_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          n_state <= EXTRACT_HASH_VAL;
        ELSE
          n_state <= HASH_MSG_PAD_AP;
        END IF;

        -- Stay in finilazization k0 ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to absorb k1 and permutation.
      WHEN AEAD_FIN_K0_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          n_state <= AEAD_FIN_K1_AP;
        ELSE
          n_state <= AEAD_FIN_K0_AP;
        END IF;

        -- Stay in finilazization k1 ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to store tag or extract tag.
      WHEN AEAD_FIN_K1_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (decrypt_s = '1') THEN
            n_state <= STORE_TAG;
          ELSE
            n_state <= EXTRACT_TAG;
          END IF;
        ELSE
          n_state <= AEAD_FIN_K1_AP;
        END IF;

        -- Stay in hash squeeze pad block ACE-permutation until 16 ACE-steps
        -- have been completed. Then go to extract hash value.
      WHEN HASH_SQZ_AP =>
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          n_state <= EXTRACT_HASH_VAL;
        ELSE
          n_state <= HASH_SQZ_AP;
        END IF;

        -- Output hash value, then go to hash squeeze permutation.
      WHEN EXTRACT_HASH_VAL =>
        IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
          IF (hash_sqz_cnt >= HASH_OUTPUTS - 1) THEN
            n_state <= IDLE;
          ELSE
            n_state <= HASH_SQZ_AP;
          END IF;
        ELSE
          n_state <= EXTRACT_HASH_VAL;
        END IF;

        -- Output tag then go to idle.
      WHEN EXTRACT_TAG =>
        IF (half_word_cnt >= TAG_HALF_WORDS - 1) THEN
          n_state <= IDLE;
        ELSE
          n_state <= EXTRACT_TAG;
        END IF;

        -- Verify that the tags match then go to idle.
      WHEN VERIFY_TAG =>
        IF (msg_auth_valid_s = '1' AND msg_auth_ready = '1') THEN
          n_state <= IDLE;
        ELSE
          n_state <= VERIFY_TAG;
        END IF;

        -- We should never end up here.
      WHEN OTHERS =>
        NULL;

    END CASE;
  END PROCESS p_next_state;

  ------------------------ Control logic decoder process -----------------------
  p_decoder : PROCESS (
    state,
    key_valid, key_ready_s, key_update, update_key_s,
    bdi_valid, bdi_ready_s, bdi_eoi, bdi_eot, bdi_valid_bytes_s, bdi_pad_loc_s,
    bdi_size, bdi_type, end_of_input_s, end_of_type_s,
    hash_in, hash_s, empty_hash_s, decrypt_in, decrypt_s,
    bdo_ready, msg_auth_s,
    half_word_cnt, ace_step_cnt, hash_sqz_cnt,
    add_pad_word_s, prev_hw_full_s)
  BEGIN
    -- Default values preventing latches
    ace_state_en      <= '0';
    srn_sel           <= SRN_SEL_SRO;
    ds_bits           <= DS_BITS_ZERO;
    scn_sel           <= SCN_SEL_SCO_DS;
    key_ready_s       <= '0';
    bdi_ready_s       <= '0';
    bdi_sel           <= '1';
    msg_auth_valid_s  <= '0';
    si_key            <= '0';
    si_nt             <= '0';
    en_bdi_buf        <= '0';
    en_tag_piso       <= '0';
    ld_tag_piso       <= '0';
    en_hash_piso      <= '0';
    ld_hash_piso      <= '0';
    bdo_valid_s       <= '0';
    bdo_valid_bytes_s <= (OTHERS => '0');
    end_of_block_s    <= '0';
    bdo_type_s        <= HDR_TAG;
    bdo_sel           <= BDO_SEL_TAG;
    n_msg_auth_s      <= msg_auth_s;
    n_end_of_input_s  <= end_of_input_s;
    n_end_of_type_s   <= end_of_type_s;
    n_add_pad_word_s  <= add_pad_word_s;
    n_prev_hw_full_s  <= prev_hw_full_s;
    n_update_key_s    <= update_key_s;
    n_hash_s          <= hash_s;
    n_empty_hash_s    <= empty_hash_s;
    n_decrypt_s       <= decrypt_s;

    CASE state IS
      WHEN IDLE =>
        n_msg_auth_s     <= '1';
        n_end_of_input_s <= '0';
        n_end_of_type_s  <= '0';
        n_add_pad_word_s <= '0';
        n_update_key_s   <= '0';
        n_hash_s         <= '0';
        n_empty_hash_s   <= '0';
        n_decrypt_s      <= '0';
        IF (key_valid = '1' AND key_update = '1') THEN
          n_update_key_s <= '1';
        END IF;
        IF (bdi_valid = '1') THEN
          IF (hash_in = '1' AND bdi_type = HDR_HASH_MSG) THEN
            n_hash_s <= '1';
            IF (bdi_size = BDI_SIZE_0) THEN
              n_empty_hash_s   <= '1';
              n_end_of_input_s <= '1';
              bdi_ready_s      <= '1';
            END IF;
          END IF;
        ELSIF (key_valid = '1' AND key_update = '1') THEN
          n_update_key_s <= '1';
        END IF;

      WHEN STORE_KEY =>
        key_ready_s <= update_key_s;
        IF (key_ready_s = '1' AND key_valid = '1') THEN
          si_key <= '1';
        END IF;

      WHEN STORE_NPUB =>
        bdi_ready_s      <= '1';
        n_end_of_input_s <= bdi_eoi;
        n_end_of_type_s  <= bdi_eot;
        n_decrypt_s      <= decrypt_in;
        IF (bdi_ready_s = '1' AND bdi_valid = '1' AND bdi_type = HDR_NPUB) THEN
          si_nt <= '1';
        END IF;

      WHEN STORE_TAG =>
        bdi_ready_s      <= '1';
        n_end_of_input_s <= bdi_eoi;
        n_end_of_type_s  <= bdi_eot;
        IF (bdi_ready_s = '1' AND bdi_valid = '1' AND bdi_type = HDR_TAG) THEN
          si_nt <= '1';
        END IF;

      WHEN AEAD_INIT_LD =>
        ace_state_en <= '1';
        srn_sel      <= SRN_SEL_LD_AEAD;
        scn_sel      <= SCN_SEL_LD_AEAD;

      WHEN AEAD_INIT_LD_AP =>
        ace_state_en <= '1';
        ds_bits      <= DS_BITS_ZERO;
        scn_sel      <= SCN_SEL_SCO_DS;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          srn_sel <= SRN_SEL_SRO_K0;
        ELSE
          srn_sel <= SRN_SEL_SRO;
        END IF;

      WHEN AEAD_INIT_K0_AP =>
        ace_state_en <= '1';
        ds_bits      <= DS_BITS_ZERO;
        scn_sel      <= SCN_SEL_SCO_DS;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          srn_sel <= SRN_SEL_SRO_K1;
        ELSE
          srn_sel <= SRN_SEL_SRO;
        END IF;

      WHEN AEAD_INIT_K1_AP =>
        ace_state_en <= '1';
        scn_sel      <= SCN_SEL_SCO_DS;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_input_s = '1') THEN
            ds_bits <= DS_BITS_ENC_DEC;
            srn_sel <= SRN_SEL_SRO_PAD;
          END IF;
        ELSE
          ds_bits <= DS_BITS_ZERO;
          srn_sel <= SRN_SEL_SRO;
        END IF;

      WHEN HASH_INIT_LD =>
        ace_state_en <= '1';
        srn_sel      <= SRN_SEL_LD_HASH;
        scn_sel      <= SCN_SEL_LD_HASH;

      WHEN HASH_INIT_LD_AP =>
        ace_state_en <= '1';
        scn_sel      <= SCN_SEL_SCO_DS;
        ds_bits      <= DS_BITS_ZERO;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_input_s = '1') THEN
            srn_sel <= SRN_SEL_SRO_PAD;
          END IF;
        ELSE
          srn_sel <= SRN_SEL_SRO;
        END IF;

      WHEN AEAD_ABSORB_AD =>
        IF (bdi_valid = '1' AND bdi_type = HDR_AD) THEN
          bdi_ready_s      <= '1';
          en_bdi_buf       <= '1';
          bdi_sel          <= '1';
          n_end_of_input_s <= bdi_eoi;
          n_end_of_type_s  <= bdi_eot;
          IF (bdi_valid_bytes_s = ALL_BDI_BYTES_VALID) THEN
            n_prev_hw_full_s <= '1';
            n_add_pad_word_s <= '1';
          ELSE
            n_prev_hw_full_s <= '0';
            n_add_pad_word_s <= '0';
          END IF;
        ELSIF (end_of_input_s = '1' OR end_of_type_s = '1') THEN
          en_bdi_buf       <= '1';
          bdi_sel          <= '0';
          n_add_pad_word_s <= '0';
        END IF;
        IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
          ace_state_en <= '1';
          srn_sel      <= SRN_SEL_SR_BDI;
          scn_sel      <= SCN_SEL_SC_DS;
          ds_bits      <= DS_BITS_AD;
        END IF;

      WHEN AEAD_ABSORB_MSG =>
        bdi_ready_s <= bdo_ready;
        IF (bdi_ready_s = '1' AND bdi_valid = '1' AND (bdi_type = HDR_PT OR bdi_type = HDR_CT)) THEN
          en_bdi_buf        <= '1';
          bdi_sel           <= '1';
          bdo_valid_s       <= '1';
          bdo_valid_bytes_s <= bdi_valid_bytes_s;
          n_end_of_input_s  <= bdi_eoi;
          n_end_of_type_s   <= bdi_eot;
          IF (decrypt_s = '0') THEN
            bdo_type_s <= HDR_PT;
          ELSE
            bdo_type_s <= HDR_CT;
          END IF;
          IF (bdi_valid_bytes_s = ALL_BDI_BYTES_VALID) THEN
            n_prev_hw_full_s <= '1';
            n_add_pad_word_s <= '1';
          ELSE
            n_prev_hw_full_s <= '0';
            n_add_pad_word_s <= '0';
          END IF;
        ELSIF (end_of_input_s = '1') THEN
          en_bdi_buf       <= '1';
          bdi_sel          <= '0';
          n_add_pad_word_s <= '0';
        END IF;
        IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
          ace_state_en <= '1';
          scn_sel      <= SCN_SEL_SC_DS;
          ds_bits      <= DS_BITS_ENC_DEC;
          IF (decrypt_s = '0') THEN
            srn_sel <= SRN_SEL_SR_BDI;
          ELSE
            srn_sel <= SRN_SEL_BDI;
          END IF;
          bdo_sel <= BDO_SEL_MSG1;
        ELSE
          bdo_sel <= BDO_SEL_MSG0;
        END IF;

      WHEN HASH_ABSORB_MSG =>
        IF (bdi_valid = '1' AND bdi_type = HDR_HASH_MSG) THEN
          bdi_ready_s      <= '1';
          en_bdi_buf       <= '1';
          bdi_sel          <= '1';
          n_end_of_input_s <= bdi_eoi;
          n_end_of_type_s  <= bdi_eot;
          IF (bdi_valid_bytes_s = ALL_BDI_BYTES_VALID) THEN
            n_prev_hw_full_s <= '1';
            n_add_pad_word_s <= '1';
          ELSE
            n_prev_hw_full_s <= '0';
            n_add_pad_word_s <= '0';
          END IF;
        ELSIF (end_of_input_s = '1') THEN
          en_bdi_buf       <= '1';
          bdi_sel          <= '0';
          n_add_pad_word_s <= '0';
        END IF;
        IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
          ace_state_en <= '1';
          srn_sel      <= SRN_SEL_SR_BDI;
          scn_sel      <= SCN_SEL_SC_DS;
          ds_bits      <= DS_BITS_ZERO;
        END IF;

      WHEN AEAD_AD_AP =>
        ace_state_en <= '1';
        scn_sel      <= SCN_SEL_SCO_DS;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_type_s = '1' OR end_of_input_s = '1') THEN
            IF (add_pad_word_s = '1') THEN
              srn_sel <= SRN_SEL_SRO_PAD;
              ds_bits <= DS_BITS_AD;
            ELSE
              IF (end_of_input_s = '1') THEN
                srn_sel <= SRN_SEL_SRO_PAD;
                ds_bits <= DS_BITS_ENC_DEC;
              ELSE
                srn_sel <= SRN_SEL_SRO;
                ds_bits <= DS_BITS_ZERO;
              END IF;
            END IF;
          ELSE
            srn_sel <= SRN_SEL_SRO;
            ds_bits <= DS_BITS_ZERO;
          END IF;
        ELSE
          srn_sel <= SRN_SEL_SRO;
          ds_bits <= DS_BITS_ZERO;
        END IF;

      WHEN AEAD_MSG_AP =>
        ace_state_en <= '1';
        scn_sel      <= SCN_SEL_SCO_DS;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_type_s = '1' OR end_of_input_s = '1') THEN
            IF (add_pad_word_s = '1') THEN
              srn_sel <= SRN_SEL_SRO_PAD;
              ds_bits <= DS_BITS_ENC_DEC;
            ELSE
              srn_sel <= SRN_SEL_SRO_K0;
              ds_bits <= DS_BITS_ZERO;
            END IF;
          ELSE
            srn_sel <= SRN_SEL_SRO;
            ds_bits <= DS_BITS_ZERO;
          END IF;
        ELSE
          srn_sel <= SRN_SEL_SRO;
          ds_bits <= DS_BITS_ZERO;
        END IF;

      WHEN HASH_MSG_AP =>
        ace_state_en <= '1';
        scn_sel      <= SCN_SEL_SCO_DS;
        ds_bits      <= DS_BITS_ZERO;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_type_s = '1' OR end_of_input_s = '1') THEN
            IF (add_pad_word_s = '1') THEN
              srn_sel <= SRN_SEL_SRO_PAD;
            ELSE
              en_hash_piso <= '1';
              ld_hash_piso <= '1';
            END IF;
          END IF;
        ELSE
          srn_sel <= SRN_SEL_SRO;
        END IF;

      WHEN AEAD_AD_PAD_AP =>
        ace_state_en <= '1';
        scn_sel      <= SCN_SEL_SCO_DS;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (end_of_input_s = '1') THEN
            srn_sel <= SRN_SEL_SRO_PAD;
            ds_bits <= DS_BITS_ENC_DEC;
          END IF;
        ELSE
          srn_sel <= SRN_SEL_SRO;
          ds_bits <= DS_BITS_ZERO;
        END IF;

      WHEN AEAD_MSG_PAD_AP =>
        ace_state_en <= '1';
        scn_sel      <= SCN_SEL_SCO_DS;
        ds_bits      <= DS_BITS_ZERO;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          srn_sel <= SRN_SEL_SRO_K0;
        ELSE
          srn_sel <= SRN_SEL_SRO;
        END IF;

      WHEN HASH_MSG_PAD_AP =>
        ace_state_en <= '1';
        srn_sel      <= SRN_SEL_SRO;
        scn_sel      <= SCN_SEL_SCO_DS;
        ds_bits      <= DS_BITS_ZERO;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          en_hash_piso <= '1';
          ld_hash_piso <= '1';
        END IF;

      WHEN AEAD_FIN_K0_AP =>
        ace_state_en <= '1';
        ds_bits      <= DS_BITS_ZERO;
        scn_sel      <= SCN_SEL_SCO_DS;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          srn_sel <= SRN_SEL_SRO_K1;
        ELSE
          srn_sel <= SRN_SEL_SRO;
        END IF;

      WHEN AEAD_FIN_K1_AP =>
        ace_state_en <= '1';
        ds_bits      <= DS_BITS_ZERO;
        scn_sel      <= SCN_SEL_SCO_DS;
        srn_sel      <= SRN_SEL_SRO;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          IF (decrypt_s = '0') THEN
            en_tag_piso <= '1';
            ld_tag_piso <= '1';
          END IF;
        END IF;

      WHEN HASH_SQZ_AP =>
        ace_state_en <= '1';
        srn_sel      <= SRN_SEL_SRO;
        scn_sel      <= SCN_SEL_SCO_DS;
        ds_bits      <= DS_BITS_ZERO;
        IF (ace_step_cnt >= ACE_STEPS - 1) THEN
          en_hash_piso <= '1';
          ld_hash_piso <= '1';
        END IF;

      WHEN EXTRACT_HASH_VAL =>
        bdo_valid_s       <= '1';
        bdo_type_s        <= HDR_HASH_VALUE;
        bdo_valid_bytes_s <= (OTHERS => '1');
        bdo_sel           <= BDO_SEL_HASH;
        IF (bdo_ready = '1') THEN
          en_hash_piso <= '1';
        END IF;
        IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
          IF (hash_sqz_cnt >= HASH_OUTPUTS - 1) THEN
            end_of_block_s <= '1';
          END IF;
        END IF;

      WHEN EXTRACT_TAG =>
        bdo_valid_s       <= '1';
        bdo_type_s        <= HDR_TAG;
        bdo_valid_bytes_s <= (OTHERS => '1');
        bdo_sel           <= BDO_SEL_TAG;
        IF (bdo_ready = '1') THEN
          en_tag_piso <= '1';
        END IF;
        IF (half_word_cnt >= TAG_HALF_WORDS - 1) THEN
          end_of_block_s <= '1';
        END IF;

      WHEN VERIFY_TAG =>
        msg_auth_valid_s <= '1';

      WHEN OTHERS =>
        NULL;

    END CASE;
  END PROCESS p_decoder;

  ------------------------ Counters process -----------------------
  p_counters_next : PROCESS (
    state,
    bdi_eot, bdi_partial_s,
    half_word_cnt, ace_step_cnt, hash_sqz_cnt,
    ace_state_en, en_bdi_buf, si_nt, si_key, en_tag_piso, en_hash_piso)
  BEGIN

    n_half_word_cnt <= half_word_cnt;
    n_ace_step_cnt  <= ace_step_cnt;
    n_hash_sqz_cnt  <= hash_sqz_cnt;

    CASE state IS
        -- Nothing to do here, reset counters
      WHEN IDLE =>
        n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
        n_ace_step_cnt  <= to_unsigned(0, n_ace_step_cnt'length);
        n_hash_sqz_cnt  <= to_unsigned(0, n_hash_sqz_cnt'length);

      WHEN STORE_KEY =>
        IF (si_key = '1') THEN
          IF (half_word_cnt >= KEY_HALF_WORDS - 1) THEN
            n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
          ELSE
            n_half_word_cnt <= half_word_cnt + 1;
          END IF;
        END IF;

      WHEN STORE_NPUB =>
        IF (si_nt = '1') THEN
          IF (half_word_cnt >= NPUB_HALF_WORDS - 1) THEN
            n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
          ELSE
            n_half_word_cnt <= half_word_cnt + 1;
          END IF;
        END IF;

      WHEN STORE_TAG =>
        IF (si_nt = '1') THEN
          IF (half_word_cnt >= TAG_HALF_WORDS - 1) THEN
            n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
          ELSE
            n_half_word_cnt <= half_word_cnt + 1;
          END IF;
        END IF;

      WHEN AEAD_ABSORB_AD =>
        IF (en_bdi_buf = '1') THEN
          IF (half_word_cnt >= BDIO_HALF_WORDS - 1 OR (bdi_eot = '1' AND bdi_partial_s = '1')) THEN
            n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
          ELSE
            n_half_word_cnt <= half_word_cnt + 1;
          END IF;
        END IF;

      WHEN AEAD_ABSORB_MSG =>
        IF (en_bdi_buf = '1') THEN
          IF (half_word_cnt >= BDIO_HALF_WORDS - 1 OR (bdi_eot = '1' AND bdi_partial_s = '1')) THEN
            n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
          ELSE
            n_half_word_cnt <= half_word_cnt + 1;
          END IF;
        END IF;

      WHEN HASH_ABSORB_MSG =>
        IF (en_bdi_buf = '1') THEN
          IF (half_word_cnt >= BDIO_HALF_WORDS - 1 OR (bdi_eot = '1' AND bdi_partial_s = '1')) THEN
            n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
          ELSE
            n_half_word_cnt <= half_word_cnt + 1;
          END IF;
        END IF;

      WHEN AEAD_INIT_LD_AP | AEAD_INIT_K0_AP | AEAD_INIT_K1_AP | HASH_INIT_LD_AP |
        AEAD_AD_AP | AEAD_MSG_AP | HASH_MSG_AP | AEAD_AD_PAD_AP |
        AEAD_MSG_PAD_AP | HASH_MSG_PAD_AP | AEAD_FIN_K0_AP |
        AEAD_FIN_K1_AP | HASH_SQZ_AP =>
        IF (ace_state_en = '1') THEN
          IF (ace_step_cnt >= ACE_STEPS - 1) THEN
            n_ace_step_cnt <= to_unsigned(0, n_ace_step_cnt'length);
          ELSE
            n_ace_step_cnt <= ace_step_cnt + 1;
          END IF;
        END IF;

      WHEN EXTRACT_HASH_VAL =>
        IF (en_hash_piso = '1') THEN
          IF (half_word_cnt >= BDIO_HALF_WORDS - 1) THEN
            n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
            IF (hash_sqz_cnt >= HASH_OUTPUTS - 1) THEN
              n_hash_sqz_cnt <= to_unsigned(0, n_hash_sqz_cnt'length);
            ELSE
              n_hash_sqz_cnt <= hash_sqz_cnt + 1;
            END IF;
          ELSE
            n_half_word_cnt <= half_word_cnt + 1;
          END IF;
        END IF;

      WHEN EXTRACT_TAG =>
        IF (en_tag_piso = '1') THEN
          IF (half_word_cnt >= TAG_HALF_WORDS - 1) THEN
            n_half_word_cnt <= to_unsigned(0, n_half_word_cnt'length);
          ELSE
            n_half_word_cnt <= half_word_cnt + 1;
          END IF;
        END IF;

      WHEN OTHERS =>
        NULL;

    END CASE;
  END PROCESS p_counters_next;

  ---------------------- Construct initialization vectors ----------------------

  ld_hash_v(STATE_WORD_A_RANGE) <= (OTHERS => '0');
  ld_hash_v(STATE_WORD_B_RANGE) <= IV_CONST;
  ld_hash_v(STATE_WORD_C_RANGE) <= (OTHERS => '0');
  ld_hash_v(STATE_WORD_D_RANGE) <= (OTHERS => '0');
  ld_hash_v(STATE_WORD_E_RANGE) <= (OTHERS => '0');

  ld_aead_v(STATE_WORD_A_RANGE) <= k0;
  ld_aead_v(STATE_WORD_B_RANGE) <= nt0;
  ld_aead_v(STATE_WORD_C_RANGE) <= k1;
  ld_aead_v(STATE_WORD_D_RANGE) <= (OTHERS => '0');
  ld_aead_v(STATE_WORD_E_RANGE) <= nt1;

  ------------------------- Primary input and output -------------------------

  -- Loaded when reading in the key and used in initilization and finilization.
  key_sipo : ENTITY WORK.SIPO_WSC(SIPO_WSC_BEH)
    GENERIC MAP(
      WORD_SIZE  => CCSW,
      WORD_COUNT => KEY_HALF_WORDS
    )
    PORT MAP(
      data_i => key,
      data_o => k_sipo_out,
      clk    => clk,
      en     => si_key
    );
  k <= swap_dw_hws(k_sipo_out);

  -- Loaded when reading in the tag and used to authenticate the msg.
  npub_tag_sipo : ENTITY WORK.SIPO_WSC(SIPO_WSC_BEH)
    GENERIC MAP(
      WORD_SIZE  => CCW,
      WORD_COUNT => NPUB_HALF_WORDS
    )
    PORT MAP(
      data_i => bdi,
      data_o => nt_sipo_out,
      clk    => clk,
      en     => si_nt
    );
  nt <= swap_dw_hws(nt_sipo_out);

  -- Choose either current 32-bits of bdi padded with 0x80*
  -- or 32-bits of 0. A second half word of 0s is needed when
  -- the input is an odd number of 32-bit half words.
  bdi_lhw <= (OTHERS => '0') WHEN prev_hw_full_s = '0' ELSE
    ACE_PAD_HALF_WORD;
  bdi_padd <= bdi_lhw WHEN bdi_sel = '0' ELSE
    padd(bdi, bdi_valid_bytes_s, bdi_pad_loc_s);

  -- 64-bits of padded bdi constructed from previously buffered 32-bits
  -- and the current 32-bits of padded bdi.
  bdi_64_p <= (bdi_buf & bdi_padd);

  -- Loaded when tag is generated and then shifts
  -- out to bdo 32-bits at a time.
  tag_piso : ENTITY WORK.PISO_WSC(PISO_WSC_BEH)
    GENERIC MAP(
      WORD_SIZE  => CCW,
      WORD_COUNT => TAG_HALF_WORDS
    )
    PORT MAP(
      data_i => swap_dw_hws(ace_step_out_tag),
      data_o => tag_piso_hw,
      clk    => clk,
      en     => en_tag_piso,
      ld     => ld_tag_piso
    );

  -- Loaded when hash-value is generated and then shifts
  -- out to bdo 32-bits at a time
  hash_piso : ENTITY WORK.PISO_WSC(PISO_WSC_BEH)
    GENERIC MAP(
      WORD_SIZE  => CCW,
      WORD_COUNT => BDIO_HALF_WORDS
    )
    PORT MAP(
      data_i => swap_w_hws(ace_step_out_sr),
      data_o => hash_piso_hw,
      clk    => clk,
      en     => en_hash_piso,
      ld     => ld_hash_piso
    );

  -- Choose bdo
  WITH bdo_sel SELECT
    bdo <= bdi_padd XOR ace_sr(W_HW0_RANGE) WHEN BDO_SEL_MSG0,
    bdi_padd XOR ace_sr(W_HW1_RANGE)WHEN BDO_SEL_MSG1,
    tag_piso_hw WHEN BDO_SEL_TAG,
    hash_piso_hw WHEN BDO_SEL_HASH,
    (OTHERS => '0') WHEN OTHERS; -- Shouldn't be possible.

  ---------------------------- Combinational logic -----------------------------

  -- Constants used in ACE-step and the SB64 funcion within.
  i_round_consts : ENTITY WORK.RSC_ROM(RSC_ROM_DF)
    PORT MAP(
      addr_i => STD_LOGIC_VECTOR(ace_step_cnt),
      d_o    => rscv
    );

  -- ACE-step entity instance, used 16 times to complete an ACE-permutation.
  ace_step : ENTITY WORK.ACE_STEP(ACE_STEP_DF)
    PORT MAP(
      s_i    => ace_state,
      sc_0_i => sc_0,
      sc_1_i => sc_1,
      sc_2_i => sc_2,
      rc_0_i => rc_0,
      rc_1_i => rc_1,
      rc_2_i => rc_2,
      s_o    => ace_step_out
    );

  -- Named portions of ACE state.
  ace_sr <= sr_from_state(ace_state);
  ace_sc <= sc_from_state(ace_state);

  -- Named portions of ACE-step output
  ace_step_out_tag <= tag_from_state(ace_step_out);
  ace_step_out_sr  <= sr_from_state(ace_step_out);
  ace_step_out_sc  <= sc_from_state(ace_step_out);

  -- XOR domain separator bits with Sc portion of
  -- ACE state and ACE-step output. Used in next Sc.
  sc_ds <= ace_sc(SC_SIZE - 1 DOWNTO 2)
    & (ace_sc(1 DOWNTO 0) XOR ds_bits);
  sco_ds <= ace_step_out_sc(SC_SIZE - 1 DOWNTO 2)
    & (ace_step_out_sc(1 DOWNTO 0) XOR ds_bits);

  -- Construct/choose Sr portion of the next state
  WITH srn_sel SELECT
    n_ace_sr <= ace_step_out_sr WHEN SRN_SEL_SRO,
    bdi_64_p WHEN SRN_SEL_BDI,
    sr_from_state(ld_hash_v) WHEN SRN_SEL_LD_HASH,
    sr_from_state(ld_aead_v) WHEN SRN_SEL_LD_AEAD,
    ace_step_out_sr XOR ACE_PAD_WORD WHEN SRN_SEL_SRO_PAD,
    ace_step_out_sr XOR k0 WHEN SRN_SEL_SRO_K0,
    ace_step_out_sr XOR k1 WHEN SRN_SEL_SRO_K1,
    bdi_64_p XOR ace_sr WHEN SRN_SEL_SR_BDI,
    ace_step_out_sr WHEN OTHERS;

  -- Construct/choose Sc portion of next state
  WITH scn_sel SELECT
    n_ace_sc <= sco_ds WHEN SCN_SEL_SCO_DS,
    sc_ds WHEN SCN_SEL_SC_DS,
    sc_from_state(ld_hash_v) WHEN SCN_SEL_LD_HASH,
    sc_from_state(ld_aead_v) WHEN SCN_SEL_LD_AEAD,
    sco_ds WHEN OTHERS;

  -- Next ACE state from next Sr and Sc portions.
  n_ace_state <= state_from_sr_sc(n_ace_sr, n_ace_sc);

END behavioral;
