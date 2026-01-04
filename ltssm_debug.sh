#!/bin/bash
# =============================================================================
# Script Name: ltssm_debug.sh
# Description:
#   This script reads and decodes the PCIe LTSSM (Link Training and Status
#   State Machine) debug registers. It parses the raw register values to
#   display the current LTSSM state and various link status indicators in a
#   human-readable table format.
#
# Usage:
#   Run as root to read from hardware:
#     sudo ./ltssm_debug.sh
#
#   Decode specific register values (offline mode):
#     ./ltssm_debug.sh <DEBUG0_VAL> <DEBUG1_VAL>
#     Example: ./ltssm_debug.sh 0x12345678 0x87654321
#
# Requirements:
#   - 'devmem2' utility must be installed and in the PATH (for hardware access).
#   - Root privileges are required to access memory via devmem2.
# =============================================================================

# -----------------------------------------------------------------------------
# LTSSM State Definitions
# Mapping of state indices to their human-readable names.
# -----------------------------------------------------------------------------
LTSSM_STATES=(
  "S_DETECT_QUIET" "S_DETECT_ACT" "S_POLL_ACTIVE" "S_POLL_COMPLIANCE"
  "S_POLL_CONFIG" "S_PRE_DETECT_QUIET" "S_DETECT_WAIT" "S_CFG_LINKWD_START"
  "S_CFG_LINKWD_ACEPT" "S_CFG_LANENUM_WAIT" "S_CFG_LANENUM_ACEPT" "S_CFG_COMPLETE"
  "S_CFG_IDLE" "S_RCVRY_LOCK" "S_RCVRY_SPEED" "S_RCVRY_RCVRCFG"
  "S_RCVRY_IDLE" "S_L0" "S_L0S" "S_L123_SEND_EIDLE" "S_L1_IDLE" "S_L2_IDLE"
  "S_L2_WAKE" "S_DISABLED_ENTRY" "S_DISABLED_IDLE" "S_DISABLED"
  "S_LPBK_ENTRY" "S_LPBK_ACTIVE" "S_LPBK_EXIT" "S_LPBK_EXIT_TIMEOUT"
  "S_HOT_RESET_ENTRY" "S_HOT_RESET" "S_RCVRY_EQ0" "S_RCVRY_EQ1"
  "S_RCVRY_EQ2" "S_RCVRY_EQ3"
)

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Helper: local utility to print Yes/No based on boolean value
yesno() {
  [[ $1 -ne 0 ]] && echo "Yes" || echo "No"
}

# Helper: read_reg
# Reads a 32-bit register value using devmem2.
# Arguments:
#   $1: Physical address to read (hex)
read_reg() {
  # Extract last hex token from devmem2 output
  local val=$(devmem2 "$1" w | awk '/0x/{val=$NF} END{print val}')
  echo $(( val ))
}

# -----------------------------------------------------------------------------
# Main Execution Logic
# -----------------------------------------------------------------------------

# Determine input source: command line arguments or hardware registers
# If arguments are provided, use them as DEBUG0 and DEBUG1 values.
# Otherwise, read from the specific hardware addresses using devmem2.
if [ $# -eq 2 ]; then
  DEBUG0=$(( $1 ))
  DEBUG1=$(( $2 ))
else
  DEBUG0=$(read_reg 0x01ffc728)
  DEBUG1=$(read_reg 0x01ffc72c)
fi

# Extract the LTSSM state (lower 6 bits of DEBUG0)
LTSSM_STATE=$(( (DEBUG0 >> 0) & 0x3f ))

printf "\n%-45s | %-25s | %-10s\n" "Description" "Value" "Decoded"
printf -- "---------------------------------------------------------------------------------------------\n"

printf "%-45s | %-25s | %-10s\n" \
  "LTSSM current state" "0x$(printf '%x' $LTSSM_STATE)" "${LTSSM_STATES[$LTSSM_STATE]}"

# -----------------------------------------------------------------------------
# Decode and Display DEBUG0 Register Fields
# -----------------------------------------------------------------------------
printf "%-45s | %-25d | %-10s\n" "PIPE transmit K indication" $(( (DEBUG0 >> 6) & 3 )) "-"
printf "%-45s | %-25s | %-10s\n" "PIPE Transmit data" "0x$(printf '%x' $(( (DEBUG0 >> 8) & 0xffff )))" "-"
printf "%-45s | %-25s | %-10s\n" "Receiver is receiving logical idle" "$(yesno $(( (DEBUG0 >> 25) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Second symbol idle (16-bit PHY only)" "$(yesno $(( (DEBUG0 >> 24) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Receiving k237 (PAD) for link number" "$(yesno $(( (DEBUG0 >> 26) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Receiving k237 (PAD) for lane number" "$(yesno $(( (DEBUG0 >> 27) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Link control bits advertised by partner" "0x$(printf '%x' $(( (DEBUG0 >> 28) & 0xf )))" "-"

# -----------------------------------------------------------------------------
# Decode and Display DEBUG1 Register Fields
# -----------------------------------------------------------------------------
printf "%-45s | %-25s | %-10s\n" "Receiver detected lane reversal" "$(yesno $(( (DEBUG1 >> 0) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "TS2 training sequence received" "$(yesno $(( (DEBUG1 >> 1) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "TS1 training sequence received" "$(yesno $(( (DEBUG1 >> 2) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Receiver reports skip reception" "$(yesno $(( (DEBUG1 >> 3) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "LTSSM reports PHY link up" "$(yesno $(( (DEBUG1 >> 4) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Skip ordered set transmitted" "$(yesno $(( (DEBUG1 >> 5) & 1 )))" "-"
printf "%-45s | %-25d | %-10s\n" "Link number confirmed by partner" $(( (DEBUG1 >> 8) & 0xff )) "-"
printf "%-45s | %-25s | %-10s\n" "Training reset requested" "$(yesno $(( (DEBUG1 >> 19) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Transmit compliance request" "$(yesno $(( (DEBUG1 >> 20) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Transmit electrical idle request" "$(yesno $(( (DEBUG1 >> 21) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Receiver detect/loopback request" "$(yesno $(( (DEBUG1 >> 22) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "LTSSM negotiated link reset" "$(yesno $(( (DEBUG1 >> 27) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Testing for polarity reversal" "$(yesno $(( (DEBUG1 >> 28) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Performing link training" "$(yesno $(( (DEBUG1 >> 29) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "In DISABLE state (link inoperable)" "$(yesno $(( (DEBUG1 >> 30) & 1 )))" "-"
printf "%-45s | %-25s | %-10s\n" "Scrambling disabled for link" "$(yesno $(( (DEBUG1 >> 31) & 1 )))" "-"
printf -- "---------------------------------------------------------------------------------------------\n"

printf "DEBUG0 = 0x%08x   DEBUG1 = 0x%08x\n\n" "$DEBUG0" "$DEBUG1"
