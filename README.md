# Bitcoin Utilities — WIF Import and Descriptor Backup

This repository contains small Bash utilities for **Bitcoin Core descriptor wallets**, with emphasis on one important use case:

> **You have one or more private keys in WIF format from an old `dumpprivkey` backup, but your current Bitcoin Core no longer provides `importprivkey`.**

The utilities provide a practical bridge between the old **"one WIF = one saved private key"** workflow and the modern **descriptor-wallet** model.

They are small shell scripts around `bitcoin-cli`, `jq`, and standard Unix / Linux tools. For security, they do not introduce a Bitcoin library or any external service into the key-handling path. All the commands issued by the scripts could also in theory be run manually on the CLI.

---

## The problem this solves

For many years, a Bitcoin Core user could do something conceptually simple:

```text
dumpprivkey <address>
```

and save the resulting WIF somewhere safe.

Years later, that same person could create a wallet and do:

```text
importprivkey <WIF>
```

That workflow was especially useful for people who kept their own paper/offline backups of individual private keys.

Bitcoin Core's wallet architecture has since moved to **descriptor wallets**. In Bitcoin Core 30.0, the legacy wallet implementation was removed, along with the legacy-only RPCs including:

- `dumpprivkey`
- `dumpwallet`
- `importprivkey`
- `importwallet`
- `importaddress`
- `importmulti`
- `importpubkey`
- and several other legacy-wallet RPCs.

See the [Bitcoin Core 30.0 release notes](https://bitcoincore.org/en/releases/30.0/).

But, there is an important distinction:

**The private key itself did not become obsolete. Only the old RPC interface for putting an individual WIF into a wallet did.**

The modern replacement is `importdescriptors`.

Bitcoin Core's descriptor wallet can still hold the private key and use it to spend. What changed is the representation used by the wallet.

---

# What this utility does

`import-wallet.sh` accepts wallet private keys, exported previously using dumpprivkey. It supports an input file containing WIF private keys, and converts each WIF into a descriptor request suitable for a modern descriptor wallet. It also supports importing a list of Descriptors from listdescriptors true.

For each WIF:

```text
< WIF >
```

the script constructs:

```text
combo(< WIF >)#< checksum >
```

and submits the resulting JSON array to:

```text
bitcoin-cli importdescriptors
```

In other words:

```text
WIF
 │
 │  wrap as combo(...)
 ▼
descriptor
 │
 │  add Bitcoin Core descriptor checksum
 ▼
importdescriptors
 │
 ▼
descriptor wallet
```

The WIF remains the private key. The descriptor is the wallet's description of how that key can be used to recognize and spend Bitcoin outputs.

Note that the descriptor is not a new private key and does not replace the WIF cryptographically. It is an update wallet/script representation built around the key.

---

# Historical Note and Why `combo()` is used

In order to support most WIF's the importer uses:

```text
combo(<WIF>)
```

rather than assuming one particular address type.

A `combo()` descriptor allows Bitcoin Core to recognize the standard output forms associated with a public key. For a compressed public key, this includes:

- P2PK
- P2PKH
- P2WPKH
- P2SH-P2WPKH

For an uncompressed public key, the applicable forms are more limited.

This makes `combo()` useful for an old `dumpprivkey` style backup because the WIF itself does not tell the importer "this was definitely a P2PKH wallet entry" in the same way a modern descriptor explicitly describes an output type.

For a typical old P2PKH address, the important representation is:

```text
pkh(<private key>)
```

but `combo()` is a convenient way to preserve compatibility with the standard output types that can be derived from the key.

Bitcoin Core's descriptor implementation confirms that `combo()` expands a compressed key into P2PK, P2PKH, P2WPKH, and P2SH-P2WPKH forms.

---

# Descriptor checksums

Bitcoin Core descriptors normally have a checksum appended with `#`.

For example:

```text
combo(Kx...private-key...)#abcd1234
```

The checksum is **not secret material**. It is an integrity check for the descriptor string.

The script obtains the correct checksum from Bitcoin Core itself using:

```text
getdescriptorinfo
```

For each WIF it effectively asks Bitcoin Core:

```text
getdescriptorinfo "combo(<WIF>)"
```

and extracts the returned `checksum`.

This is preferable to implementing the descriptor checksum algorithm in Bash.

`getdescriptorinfo` also tells Bitcoin Core to canonicalize/analyze the descriptor and reports whether private keys are present.

See the [Bitcoin Core `getdescriptorinfo` documentation](https://bitcoincore.org/en/doc/31.0.0/rpc/util/getdescriptorinfo/).

---

# Input format

The normal input is a plain text file containing **one WIF per line**:

```text
Kx123...
Lx456...
Kw789...
```

Blank lines are skipped.

The file should contain the actual WIF private keys, not addresses.

For example:

```bash
./import-wallet.sh -w recovery -f keys.txt
```

The `.gitignore` included with this repository already ignores:

```text
keys.txt
```

That is intentional. Using the input filename keys.txt is recommended but is not required.

---

# What the importer creates

If the requested wallet does not already exist, the script creates a new descriptor wallet.

The wallet is created with:

```text
descriptors=true
disable_private_keys=false
```

and with the supplied passphrase.

That means this is a **normal spend-capable descriptor wallet**, not a watch-only wallet.

The resulting wallet contains the private keys represented by the imported descriptors.

The script then calls:

```text
importdescriptors
```

with a request array resembling:

```json
[
  {
    "desc": "combo(<WIF>)#<checksum>",
    "timestamp": 0
  },
  {
    "desc": "combo(<WIF>)#<checksum>",
    "timestamp": 0
  }
]
```

Bitcoin Core rescans the blockchain according to the timestamps supplied with the descriptors.

---

# Timestamp Rescan Support

By default, the script uses:

```text
timestamp = 0
```

which means "from the beginning of the blockchain."

This is the safest default when the age of the key or its first use is unknown.

For an old key that could have received coins many years ago, do **not** arbitrarily choose a recent timestamp merely to make the rescan faster. Doing so could cause earlier transactions to be missed.

To make the scan faster, if you know that the key could not have been used before a particular block height, the script supports:

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

# Bitcoin Core RPC timeout

The importer deliberately invokes:

```text
-rpcclienttimeout=0
```

for the `importdescriptors` call.

This matters because a historical rescan can take a long time. The import itself may continue successfully even when a normal RPC client timeout expires.

Setting the CLI's RPC client timeout to zero prevents the command-line client from giving up while Bitcoin Core is still performing the import.

---

# Basic setup

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

---

# A note about wallet creation

The current Bitcoin Core architecture requires descriptor wallets.

The script therefore creates the wallet using the descriptor-wallet mode rather than attempting to create a legacy BDB wallet.

Conceptually, this replaces the old workflow:

```text
create legacy wallet
        ↓
importprivkey
        ↓
wallet.dat
```

with:

```text
create descriptor wallet
        ↓
WIF → descriptor
        ↓
importdescriptors
        ↓
descriptor wallet
```

This is why an old WIF backup remains usable even though the old `importprivkey` RPC is gone.

---

# Verifying an imported key

A useful independent check is to ask Bitcoin Core to derive an address from the descriptor.

For example, the underlying descriptor can be analyzed with:

```bash
bitcoin-cli getdescriptorinfo 'pkh(<WIF>)'
```

or:

```bash
bitcoin-cli getdescriptorinfo 'combo(<WIF>)'
```

and addresses can be derived using `deriveaddresses` where appropriate.

The important principle is:

> **Do not substitute a derived address, public key, or descriptor checksum for the private key when making the original private-key backup.**

The WIF is the private key material.

The descriptor is a reusable wallet representation of that key.

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

# Why this is different from the old `dumpprivkey` workflow

The old workflow was pleasantly simple:

```text
address
   ↓
dumpprivkey
   ↓
WIF
   ↓
store WIF
   ↓
importprivkey
```

The modern descriptor-wallet workflow is more explicit:

```text
WIF
   ↓
descriptor construction
   ↓
checksum
   ↓
importdescriptors
   ↓
descriptor wallet
```

The additional representation is not required by Bitcoin's cryptography. It is required by the wallet architecture.

This utility exists to make that architectural change transparent to someone who already has the old kind of backup.

---

# The "Rip Van Winkle" use case

This repository is particularly useful for the person who did exactly what Bitcoin Core once encouraged users to do:

1. Receive Bitcoin.
2. Obtain a private key with `dumpprivkey`.
3. Print or otherwise securely store the WIF.
4. Put the wallet away.
5. Come back many years later.

If that person returns to a current Bitcoin Core installation, the old:

```text
importprivkey
```

command is no longer available because the legacy wallet system has been removed.

The conventional migration answer is to install an older Bitcoin Core release, create/load a legacy wallet, import the keys there, migrate the wallet to descriptors, and then upgrade.

That works, but it introduces an unnecessary version detour for someone whose actual requirement is simply:

> **"I have my private keys. Put them into a modern wallet."**

This utility takes the shorter path:

```text
old WIF backup
      ↓
modern descriptor wallet
```

No legacy wallet is required.

---

# Security considerations

This software handles **private keys**.

Use it accordingly.

## Do not

- Put WIF files into Git.
- Commit `.bitcoin-utilities.sh`.
- Paste WIFs into web sites.
- Upload WIFs to online services.
- Send descriptor exports containing private keys to other people.
- Leave WIFs or private descriptors in shell history unnecessarily.
- Run the scripts on a machine you do not trust.

## Remember

A WIF is private-key material.

A descriptor containing the private key is also private-key material.

A checksum is not private.

A public-only descriptor is not private-key material.

The distinction matters when deciding what can safely be copied to an ordinary backup location.

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

This project is intentionally narrow.

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
- `openssl`
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

# Important conceptual point

The disappearance of `importprivkey` does **not** mean that old WIF backups have become incompatible with Bitcoin.

It means that the old wallet interface for representing those keys has disappeared.

The underlying relationship remains:

```text
WIF
  ↓
private key
  ↓
public key
  ↓
script / address representation
  ↓
descriptor
```

The descriptor is simply the modern wallet-language representation of that relationship.

This utility bridges the gap so that a person who preserved the **actual cryptographic primitive** — the private key — does not have to resurrect an obsolete wallet implementation merely to make that key usable again.

---

## References

- [Bitcoin Core 30.0 release notes](https://bitcoincore.org/en/releases/30.0/)
- [Bitcoin Core `importdescriptors` RPC](https://bitcoincore.org/en/doc/31.0.0/rpc/wallet/importdescriptors/)
- [Bitcoin Core `getdescriptorinfo` RPC](https://bitcoincore.org/en/doc/31.0.0/rpc/util/getdescriptorinfo/)
- [Bitcoin Core descriptor documentation/source](https://doxygen.bitcoincore.org/)
