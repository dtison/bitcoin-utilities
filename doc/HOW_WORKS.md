# A Closer Look at What this Utility does and How it works

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

Note that the descriptor does not replace private key. It is an update wallet/script representation built around the key.

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

# Bitcoin Core RPC timeout

The importer deliberately invokes:

```text
-rpcclienttimeout=0
```

for the `importdescriptors` call.

This matters because a historical rescan can take a long time. The import itself may continue successfully even when a normal RPC client timeout expires.

Setting the CLI's RPC client timeout to zero prevents the command-line client from giving up while Bitcoin Core is still performing the import.

---

# A note about wallet creation

The current Bitcoin Core architecture requires descriptor wallets.

The script therefore creates the wallet using the descriptor-wallet mode rather than attempting to create a legacy BDB wallet.


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
