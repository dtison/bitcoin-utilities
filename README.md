# Bitcoin Utilities — Private Key Import for Descriptor Wallets - Descriptors Exports

Have an old WIF private-key backups but no importprivkey in modern Bitcoin Core?

bitcoin-utilities provides a bridge from WIF-based backups to modern descriptor wallets, allowing individual private keys to be imported using Bitcoin Core's importdescriptors RPC.

The terms Private Key and WIF are synonyms and used interchangeably.

## ⚠️ Warning

Every effort has been made to ensure that this tool is safe to use. Nevertheless, using any software that handles Bitcoin private keys inherently involves risk.

**Read and thoroughly review the Security section before using, and do not proceed unless you are 100% confident that you understand what you are doing.** This tool is not intended for casual or careless users. You are solely responsible for your actions and for the security of your Bitcoin. **There is no warranty.** Please read `doc/LICENSE.md` in its entirety.

A single careless mistake can result in the permanent loss of your Bitcoin. **Review the source code thoroughly and verify your environment before using this software.**

---
## Additional Info

If you want additional technical details, see [See How it Works](doc/HOW_WORKS.md).
For a deeper-dive into the problem being solved, see [Import Gap Details](doc/IMPORT_GAP_DETAILS.md).


This repository contains small Bash utilities for **Bitcoin Core descriptor wallets**, with one principal use case:

> **You have one or more private keys in WIF format from an old `dumpprivkey` backup, but the current version of Bitcoin Core no longer provides `importprivkey`.**
>
> There is no officially-supported workaround. The latest version of Bitcoin Core can not open Legacy wallet.dat files, and it is also unable to restore a wallet from the Bitcoin Private Key.

The utilities provide a practical bridge between the old **"one WIF = one saved private key"** workflow and the modern **descriptor-wallet**.

They are small shell scripts around `bitcoin-cli`, `jq`, using standard Unix / Linux tools. For security, they do not introduce any Bitcoin library and do not make any network connections except to the official Bitcoin Core PRC that you have running locally.

---

## Platform Support

`bitcoin-utilities` was developed on Linux. It should also support **macOS**. The scripts are written in Bash and use standard Unix utilities together with the Bitcoin Core command-line tools, so apart from jq, no separate runtime or application framework is required. Mac Users can use Homebrew or Mac Ports to install jq.

**Windows users can use WSL 2 (Windows Subsystem for Linux)** to provide a Linux environment in which to run the tools. WSL 2 allows the scripts to be used without requiring the utilities to be rewritten specifically for Windows PowerShell or Command Prompt.

The Bitcoin Core installation and `bitcoin-cli` executable must, of course, be available within the environment where the scripts are being run. See the installation and configuration instructions below for platform-specific details.

---
### Windows / WSL 2 and MacOS Testing

**macOS and Windows testing is still needed.**

If you are an experienced MacOS or Windows user and can help test `bitcoin-utilities` with Bitcoin Core, we'd appreciate your help. 

If you can help, please **open an issue on GitHub** with your setup, what you tested, and your results. Your findings can help us document straightforward procedures for Mac and Windows users.

---

## Review of The Problem

For many years, a Bitcoin Core user could do something conceptually simple:

```text
dumpprivkey <address>
```

and save the resulting Private Key (WIF) somewhere safe.

To restore the funds, the same person expected to be able to create a new wallet and do:

```text
importprivkey <WIF>
```

That traditional workflow was especially useful for paper or other offline backups of individual private keys.

Bitcoin Core's wallet architecture has since moved to **descriptor wallets**. In Bitcoin Core 30.0, **the legacy wallet implementation was removed**, along with the associated legacy RPCs:

- `dumpprivkey`
- `dumpwallet`
- `importprivkey`
- `importwallet`
- `importaddress`
- `importmulti`
- `importpubkey`
- and several other legacy-wallet RPCs.

See the [Bitcoin Core 30.0 release notes](https://bitcoincore.org/en/releases/30.0/).

But, there is an important stipulation:

**The private key itself has not become unusable, but the RPC and Console interface for importing it into a Descriptor wallet did.**

The modern workflow is to use `importdescriptors` which is incompatible with legacy Private Keys.

---

# Security

This software handles **private keys**.

One wrong move and you could lose all your Bitcoin.

**Think twice before you act.**

Consider using an encrypted device or volume.

Do not use where any cameras are present.

Do not use where others can see your display.

## Do not

- Paste Private Keys into any web sites.
- Upload Private Keys to any Storage or Cloud services, or send via email.
- Descriptor wallet exports are the same risk, if made using listdescriptors true.
- Leave Private Keys or your Passphrase in your shell history.
- Run the scripts on a machine you do not trust, or with unverified software (See note below, **Verify Bitcoin Core Before Use** )

## Remember

A WIF is private-key material.

A descriptor containing the private key is also private-key material.

Handle with care the Passphrase you send on the command line or in .bitcoin-utilities.sh

The checksum and public-only descriptors are safe.

### Verify Bitcoin Core Before Use

Before using this tool, **verify the Bitcoin Core binaries you are going to run**. At an absolute minimum, verify the SHA-256 checksum of your downloaded Bitcoin Core release against the official `SHA256SUMS` file published by the Bitcoin Core project. For stronger verification, use GPG to verify the signatures on `SHA256SUMS.asc` and verify the signing keys and fingerprints you trust. Bitcoin Core provides platform-specific instructions for both methods on its official [Download and Verification](https://bitcoincore.org/en/download/) page.

Do not assume that a Bitcoin Core binary is trustworthy merely because it was downloaded from a site that appears legitimate. **Verify it before using it with private keys.** If the verification fails, stop and do not use the software.

### Start With Small Amounts

When first using `bitcoin-utilities`, **always begin with a small amount of Bitcoin**. Use a test wallet and keys containing only an amount you can afford to lose. Work through the complete import, verification, backup, and recovery process until you are completely familiar and confident with the tool and its behavior.

Only after you have independently verified that the process works as expected should you consider using the tool with significant amounts of Bitcoin.

**Never make your first attempt with your life savings.**

### Shell Command History

**Be aware that anything you enter on the command line may be recorded in your shell's command history.** Depending on your shell, this may be stored in `~/.bash_history` (Bash) or `~/.zsh_history` (Zsh). If you supply a WIF, wallet passphrase, or other sensitive value directly as a command-line parameter, that value may therefore remain in your shell history after the command has completed.

There are several ways to prevent sensitive commands from being recorded in shell history, and commands can also be removed from history after the fact. However, history behavior varies by shell and configuration, so **do not assume that a command containing private-key material or a passphrase will automatically disappear from history**. Understand how history works in your particular environment before using sensitive command-line arguments.

See the official documentation for your shell:

- [GNU Bash — Using History Interactively](https://www.gnu.org/software/bash/manual/html_node/Using-History-Interactively.html) — including `HISTCONTROL`, `HISTIGNORE`, `HISTFILE`, and related history controls.
- [Zsh — User's Guide / History](https://zsh.sourceforge.io/Guide/zshguide.html) — including `HIST_IGNORE_SPACE` and other history controls.

**Treat your shell history as sensitive data when working with Bitcoin private keys.** Before using this tool, understand exactly what your shell records, where it stores that history, and how to remove sensitive entries if necessary.


---

### What This Tool Actually Does

`bitcoin-utilities` is intentionally a **thin automation layer over the Bitcoin Core RPC interface**. It does not implement a Bitcoin wallet, replace Bitcoin Core, or provide an alternative Bitcoin implementation.

The operations performed by these scripts are carried out through the Bitcoin Core RPC interface using `bitcoin-cli`. The scripts primarily automate and sequence operations that an experienced user could perform manually—for example, obtaining descriptor information, constructing the appropriate `importdescriptors` requests, importing them into a descriptor wallet, and exporting reusable descriptors.

In other words, **Bitcoin Core does the actual wallet work**. These scripts provide a convenient, repeatable way to perform the necessary RPC operations without requiring the user to construct and execute each command manually.

**The scripts do not send private keys to an external service or rely on a third-party Bitcoin API.** Their purpose is to make the transition from WIF-based key backups to modern descriptor wallets practical while keeping the underlying operations within the user's own Bitcoin Core installation.



---

# Timestamps and Rescans

By default, the script uses:

```text
timestamp = 0
```

which means "from the beginning of the blockchain."

This is the safest default when the age of the key or its first use is unknown.

To make the scan faster, if you know that the key was not used before a particular block height, the script will save time by using:

```bash
-t <block-height>
```

It obtains that block's timestamp from Bitcoin Core and uses it as the import timestamp.

For example:

```bash
./import-wallet.sh -w recovery -f keys.txt -t 600000
```

The intent is:

```text
known-safe historical starting point
        ↓
block height
        ↓
block timestamp
        ↓
descriptor import timestamp
        ↓
blockchain rescan
```

`importdescriptors` rescans based on the earliest timestamp among the descriptors being imported. An early timestamp can therefore make the operation take a substantial amount of time.

See the [Bitcoin Core `importdescriptors` documentation](https://bitcoincore.org/en/doc/26.0.0/rpc/wallet/importdescriptors/).

---

# Basic Setup

The repository expects a local configuration file:

```text
.bitcoin-utilities.sh
```

Create it from the example:

```bash
cp .bitcoin-utilities.sh.example .bitcoin-utilities.sh
```

Edit it:

```bash
BITCOIN_PATH="${HOME}/bitcoin-31.1/bin"
PASSPHRASE='your-wallet-passphrase'
```

`BITCOIN_PATH` must point to the directory containing:

```text
bitcoin-cli
```

The configuration file is ignored by Git.

You can also specify PASSPHRASE and BITCOIN_PATH on the command line. Use -p <path> and -P <passphrase}

**Do not put this configuration file into a public repository.**

---

# Importing WIFs

Create a file such as:

```text
keys.txt
```

with one WIF per line.

Then run:

```bash
./import-wallet.sh -w recovery -f keys.txt
```

The main options are:

```text
-w wallet       Wallet name
-f filename     Input file containing WIFs
-p path         Bitcoin Core executable path
-P passphrase   Wallet passphrase
-t height       Block height used to establish the import timestamp
-d              Debug output
-h              Help
```

For example:

```bash
./import-wallet.sh \
    -w recovery \
    -f keys.txt \
    -t 500000
```

The wallet is created if necessary.

If the wallet already exists, the script attempts to import into that wallet.

If the -f keys.txt parameter is omitted, it will default to "keys.txt".

---

# Creating a reusable descriptor backup

Once the keys have been imported, the second utility can export the wallet's descriptors:

```bash
./list-descriptors.sh -w recovery
```

The script performs:

```text
listdescriptors true
```

and extracts the wallet's `descriptors` array.

The `true` argument is significant: it asks Bitcoin Core to include private key material in the exported descriptors.

The output can therefore contain descriptors that are sufficient to recreate the spend-capable wallet.

A descriptor backup might conceptually look like:

```json
[
  {
    "desc": "combo(<private-key>)#<checksum>",
    "active": false,
    "internal": false,
    "timestamp": 1234567890,
    ...
  }
]
```

The exact descriptor set and fields depend on the wallet.

**Treat this output as highly sensitive.**

A descriptor containing private key material is effectively another form of private-key backup.

---

# Why the descriptor backup is useful

The WIF backup and descriptor backup serve slightly different purposes.

### WIF backup

The WIF is the minimal private-key representation:

```text
Kx...
```

It is essentially:

```text
private key + encoding/version information
```

It does not itself tell a descriptor wallet how you want that key represented as wallet output scripts.

### Descriptor backup

The descriptor records the wallet's interpretation of the key:

```text
combo(<private key>)#checksum
```

or another descriptor appropriate to the wallet.

It therefore preserves both:

```text
private key
+
wallet/script representation
```

This makes the descriptor export directly reusable with `importdescriptors`.

The important idea is that **the descriptor is derived from the primitive private key; it is not a replacement for the underlying cryptographic secret.**

---

# Restoring from the descriptor backup

A descriptor export can be fed back to Bitcoin Core's `importdescriptors` RPC.

The RPC expects a **JSON array**, not the complete object returned by `listdescriptors`.

For example, this:

```json
{
  "wallet_name": "recovery",
  "descriptors": [
    ...
  ]
}
```

is the response object.

The part needed by `importdescriptors` is:

```json
[
  ...
]
```

That distinction is important when moving a descriptor backup between wallets or scripts.

---

# Passphrase handling

The example configuration stores the wallet passphrase in:

```text
.bitcoin-utilities.sh
```

This is convenient for a small local utility but is not a hardened secret-management system.

The repository's `.gitignore` excludes this file.

For a higher-security environment, consider changing the scripts so the passphrase is supplied interactively or through an appropriate secret-management mechanism rather than stored in a plaintext configuration file.

Also note that the current debug/display code can print the configured passphrase when debugging is enabled. **Do not use `-d` in an environment where command output is being recorded or shared if the passphrase must remain confidential.**

---

# What this utility does not do

For securiyt, this project is intentionally narrow.

It does **not**:

- contact an external blockchain service;
- upload private keys;
- implement a Bitcoin wallet;
- implement private-key cryptography itself;
- replace Bitcoin Core;
- create a seed phrase from individual WIFs;
- reconstruct an unknown HD wallet from arbitrary WIFs;
- determine which historical address a WIF originally came from.

Bitcoin Core remains responsible for descriptor parsing, checksum generation, key handling, blockchain scanning, and wallet storage.

The scripts are primarily an automation layer around Bitcoin Core RPCs.

---

# Requirements

The scripts assume a Unix-like environment with:

- Bash
- Bitcoin Core with descriptor-wallet support
- `bitcoin-cli`
- `jq`
- standard Unix utilities

The repository was developed/tested around Bitcoin Core 31.x.

Bitcoin Core 30.0 and later no longer support creation/loading of legacy BDB wallets and have removed the legacy-only `importprivkey` RPC, making the descriptor approach the intended path for current Core releases.

---

# Files

```text
.
├── .bitcoin-utilities.sh.example
├── .gitignore
├── README.md
├── functions.sh
├── import-wallet.sh
└── list-descriptors.sh
```

### `import-wallet.sh`

Imports wallet material into a descriptor wallet. It can accept WIF private keys from a text file, convert each WIF into a `combo()` descriptor, and import descriptor lists using `importdescriptors`.

### `list-descriptors.sh`

Exports the wallet's descriptors using:

```text
listdescriptors true
```

The result is reduced to the reusable `descriptors` array.

### `functions.sh`

Shared argument handling and utility functions.

### `.bitcoin-utilities.sh.example`

Example local configuration.

---

# Recommended recovery procedure

For an old WIF backup, the recommended workflow is:

```text
                 OLD BACKUP
                     │
                     ▼
              keys.txt (WIFs)
                     │
                     ▼
             import-wallet.sh
                     │
                     ▼
          modern descriptor wallet
                     │
                     ▼
             verify balances
                     │
                     ▼
          list-descriptors.sh
                     │
                     ▼
       reusable descriptor backup
```

After the wallet has been successfully restored and verified, maintain at least one independent offline backup of the private-key material.

Do not rely on the wallet's live database as the only copy.

---

## References

- [Bitcoin Core 30.0 release notes](https://bitcoincore.org/en/releases/30.0/)
- [Bitcoin Core `importdescriptors` RPC](https://bitcoincore.org/en/doc/31.0.0/rpc/wallet/importdescriptors/)
- [Bitcoin Core `getdescriptorinfo` RPC](https://bitcoincore.org/en/doc/31.0.0/rpc/util/getdescriptorinfo/)
- [Bitcoin Core descriptor documentation/source](https://doxygen.bitcoincore.org/)
