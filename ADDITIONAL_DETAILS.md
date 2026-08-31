
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