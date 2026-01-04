# pcie-ltssm-script

## Description
`ltssm_debug.sh` is your new best friend! This script makes it super easy to peek into your hardware's LTSSM state by turning raw, confusing register values into a clean, human-readable table. Let's debug your PCIe link training issues!

## Requirements
*   **Linux Environment**: The script is designed to run in a Linux environment.
*   **`devmem2`**: This utility is required for reading hardware registers directly. It must be installed and available in the system `PATH`.
*   **Root Privileges**: Accessing hardware registers via `devmem2` requires root (`sudo`) privileges.

## Usage

### Hardware Mode
To read directly from the hardware registers, run the script with root privileges:

```bash
sudo ./ltssm_debug.sh
```

### Offline Mode
To decode specific register values captured previously or from another source, pass the values of `DEBUG0` and `DEBUG1` as arguments:

```bash
./ltssm_debug.sh <DEBUG0_VAL> <DEBUG1_VAL>
```

**Example:**
```bash
./ltssm_debug.sh 0x12345678 0x87654321
```

## Use Case

### Dump ltssm state

* Run script in loop to dump ltssm state.

```bash
while true; do sudo ./ltssm_debug.sh; sleep <x>; done
```

```bash
LTSSM current state                           | 0x7                       | S_CFG_LINKWD_START      
LTSSM current state                           | 0x4                       | S_POLL_CONFIG      
LTSSM current state                           | 0x0                       | S_DETECT_QUIET     
LTSSM current state                           | 0x7                       | S_CFG_LINKWD_START     
LTSSM current state                           | 0xb                       | S_CFG_COMPLETE     
LTSSM current state                           | 0x4                       | S_POLL_CONFIG       
LTSSM current state                           | 0x4                       | S_POLL_CONFIG          
LTSSM current state                           | 0x0                       | S_DETECT_QUIET         
LTSSM current state                           | 0x4                       | S_POLL_CONFIG     
LTSSM current state                           | 0xf                       | S_RCVRY_RCVRCFG
```
### Dump data when ltssm state is L0

```bash
S_L0                       2487
S_L0                       87a5
S_L0                       e757
S_L0                       731a
S_L0                       c663
```

### Dump data when link is in S_POLL_CONFIG

* Transmits TS2s with PAD for Link and Lane Number.
* Transitions to Configuration when:
    * 16 TS2s sent after receiving first TS2.
    * 8 consecutive TS2s received with PAD.
* Timeout: 48ms (returns to Detect).

```bash
S_POLL_CONFIG              f7bc  <<< PAD - f7 Link
S_POLL_CONFIG              2cf7  <<< PAD - f7 Lane
S_POLL_CONFIG              0006  <<< 06 - Data rate 5Gbps
S_POLL_CONFIG              4545  <<< Type TS2
S_POLL_CONFIG              4545  <<< Type TS2
S_POLL_CONFIG              4545  <<< Type TS2
S_POLL_CONFIG              4545  <<< Type TS2
```

### Dump data when link is in S_CFG_LINKWD_START

* Transmits TS1s with Link Number (0-31) and PAD for Lane Number.
* Transitions to Configuration.Linkwidth.Accept when:
    * Two consecutive TS1s received with matching Link Number and PAD for Lane Number.
* Timeout: 24ms (returns to Detect).

```bash
S_CFG_LINKWD_START         04bc  <<< link - 04 << arbitrary
S_CFG_LINKWD_START         2cf7  <<< PAD - f7(K23.7 encoding) for Lane number
S_CFG_LINKWD_START         0006  <<< Data Rate 5Gbps
S_CFG_LINKWD_START         4a4a  <<< Type TS1
S_CFG_LINKWD_START         4a4a  <<< Type TS1
S_CFG_LINKWD_START         4a4a  <<< Type TS1
S_CFG_LINKWD_START         4a4a  <<< Type TS1
```

### Read ltssm debug0 and debug1.

```bash
Description                            | Value  | Decoded
------------------------------------------------------------------
LTSSM current state                    | 0xf    | S_RCVRY_RCVRCFG
PIPE transmit K indication             | 0      | -
PIPE Transmit data                     | 0x4545 | -
Receiver is receiving logical idle     | No     | -
Second symbol idle (16-bit PHY only)   | No     | -
Receiving k237 (PAD) for link number   | No     | -
Receiving k237 (PAD) for lane number   | No     | -
Link control bits advertised by partner| 0x9    | -  <<<< requesting for scrambler disable
```

## Output Description
The script outputs a table with three columns:
*   **Description**: The name of the LTSSM state or link status bit.
*   **Value**: The raw value extracted from the register.
*   **Decoded**: The human-readable interpretation (e.g., State Name, Yes/No).

## License
This project is licensed under the **GNU General Public License v2.0**.
See the [LICENSE](LICENSE) file for details.
