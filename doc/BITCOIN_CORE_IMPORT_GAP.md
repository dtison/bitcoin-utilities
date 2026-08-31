# Why This Tool Exists

## The Bitcoin Core Import Gap

With the release of **Bitcoin Core 30.0**, support for legacy Berkeley DB (BDB) wallets was removed. Legacy wallets can no longer be created or loaded by current Bitcoin Core, and the legacy-only wallet RPCs were removed as well. Among them are the two commands that matter most to users of old individual-key backups:

```text
dumpprivkey
importprivkey
```

The Bitcoin Core 30.0 release notes explicitly list both RPCs among those removed.

This is not an accidental regression. It is the completion of a deliberate transition from the old **key-based legacy wallet model** to the modern **descriptor-based wallet model**. Bitcoin Core's documentation describes `importdescriptors` as the corresponding mechanism for importing into descriptor wallets.

### Why this matters to an old Bitcoin backup

If, years ago, you used:

```text
dumpprivkey <address>
```

to make a backup, you may have deliberately chosen **not** to retain the original `wallet.dat`.

That was a perfectly reasonable backup strategy under the old wallet model. `dumpprivkey` gave you the private key in **WIF (Wallet Import Format)**, and that WIF was the essential cryptographic secret needed to recover control of the corresponding Bitcoin.

Some users printed their WIFs and created what were effectively paper backups. Others stored them offline in encrypted files, physical media, or other forms of cold storage.

The important point is this:

> **Those WIFs have not become obsolete. The Bitcoin private keys they contain are still valid. What changed is Bitcoin Core's ability to directly import them using the old `importprivkey` interface.**

Before Bitcoin Core 30.0, the recovery path was straightforward:

```text
WIF backup
    │
    ▼
importprivkey
    │
    ▼
Legacy wallet
```

With current Bitcoin Core, that path no longer exists.

## What are the alternatives?

A user with an old WIF backup now has several practical choices.

### 1. Preserve an old Bitcoin Core release

Keep a verified copy of a Bitcoin Core release that still supports legacy-wallet import, such as **Bitcoin Core 29.4**, as part of the long-term recovery strategy.

This preserves the old workflow:

```text
WIF
  │
  ▼
importprivkey
  │
  ▼
Legacy wallet
```

The disadvantage is obvious: your cold-storage procedure now depends on preserving not only your Bitcoin backup, but also a specific historical software environment capable of consuming it.

For a backup intended to last decades, that is an additional dependency to maintain, document, preserve, and periodically verify.

### 2. Migrate to descriptors

Another approach is to use an older Core release to import the WIFs and then migrate the resulting legacy wallet to a descriptor wallet.

That produces a modern wallet that can be used with current Bitcoin Core.

However, this changes the form of the recovery material and the recovery procedure. A user who deliberately created a minimal WIF-only backup may not want to redesign an already-established long-term cold-storage system simply because the wallet software changed.

And importantly, migration does **not** make the original WIF private keys invalid. The WIFs remain valid. What changes is the wallet representation and the procedure required to restore the wallet in current Core.

### 3. Use another wallet

A third option is to use another Bitcoin wallet that provides a WIF/private-key import facility.

There are wallets and utilities that can perform this function.

But this introduces another consideration: **trust and behavior**.

A user may have deliberately chosen Bitcoin Core as the software they trust to manage their Bitcoin. They may not want to introduce another wallet merely to bridge a software-interface change.

There can also be significant differences in how wallets handle imported keys. For example, a wallet may choose to sweep an imported key by creating a transaction that moves the Bitcoin to a newly generated address. That is fundamentally different from simply importing the existing private key into the wallet.

A user may reasonably prefer not to perform such a transaction at all.

## None of these solutions is particularly satisfying

For someone who already performed a careful long-term backup, the first two options can be especially inconvenient.

Perhaps the backup is stored in a distant physical location. Perhaps it consists of printed WIFs kept with other cold-storage material. Perhaps the entire backup procedure was designed, documented, tested, and independently verified years ago.

Adding a set of historical Bitcoin Core binaries to that backup is cumbersome.

Likewise, rebuilding the recovery process around descriptor wallets may require substantially more work than the original backup procedure. It may require recovering an old software environment, importing the keys, migrating the wallet, generating new descriptor-based backups, and then verifying the new arrangement.

The objection is not that these procedures are impossible.

The objection is that **they are disproportionate to the actual problem**.

The user already possesses the thing that matters most:

```text
the private key
```

The problem is simply that modern Bitcoin Core no longer provides the old command that accepted it.

## Was `importprivkey` simply forgotten?

No.

The removal was deliberate.

Bitcoin Core 30.0 removed the BDB legacy wallet implementation and the legacy-only RPCs, including `dumpprivkey` and `importprivkey`. The release notes explicitly describe legacy wallets as no longer creatable or loadable and point users toward migration to descriptor wallets.

The underlying architectural change goes back much further. Descriptor wallets were introduced as a different wallet model in which the wallet explicitly stores the scripts it considers to belong to it, rather than maintaining the older implicit relationship between a collection of keys and the scripts that can be derived from them. Consequently, descriptor wallets use `importdescriptors` rather than the old collection of key/script import RPCs.

There has, however, been recognition within Bitcoin Core development that the loss of the old convenience interface creates a usability problem. Bitcoin Core issue [#30175](https://github.com/bitcoin/bitcoin/issues/30175) specifically proposes enabling `importprivkey`-style functionality for descriptor wallets. The issue notes that the exact legacy semantics cannot be reproduced, but that the likely user intent of `importprivkey` can often be mapped to a `combo()` descriptor.

That observation is particularly relevant here.

The old user's intent was usually very simple:

> **"I have this private key. Make this key usable by my wallet."**

For a single private key, that intent can be represented in the descriptor model.

## This is where `bitcoin-utilities` comes in

`bitcoin-utilities` is a **bridge between the old WIF-based backup model and the modern descriptor-wallet model**.

It does not resurrect the legacy wallet system.

It does not modify Bitcoin Core.

It does not require a legacy `wallet.dat`.

Instead, it takes the private-key material that an old `dumpprivkey` backup produced and translates it into the representation that a modern descriptor wallet understands.

Conceptually:

```text
             OLD BACKUP
                 │
                 │
                WIF
                 │
                 ▼
        ┌─────────────────┐
        │ bitcoin-utilities│
        │   import bridge  │
        └────────┬────────┘
                 │
                 ▼
        descriptor + checksum
                 │
                 ▼
        importdescriptors
                 │
                 ▼
       MODERN DESCRIPTOR WALLET
```

The result is that a user can recover the practical functionality they previously had:

```text
"I have a WIF.
Put this private key into my Bitcoin Core wallet."
```

without first resurrecting a legacy wallet implementation.

The bridge also works in the other direction. Once the keys are represented in a descriptor wallet, the wallet's descriptors can be exported and retained as a **reusable descriptor backup**.

Thus the workflow becomes:

```text
Old WIF backup
      │
      ▼
 import-wallet.sh
      │
      ▼
Modern descriptor wallet
      │
      ▼
list-descriptors.sh
      │
      ▼
Reusable descriptor backup
```

This does not make the original WIF backup obsolete. Rather, it gives the user an additional modern representation that can be restored directly with `importdescriptors`.

## The goal

The goal of this project is therefore not to reproduce the legacy wallet architecture.

It is much simpler:

> **Preserve the practical functionality that users relied upon when `dumpprivkey` and `importprivkey` existed, while using the descriptor-wallet architecture that current Bitcoin Core requires.**

The user should not have to become a descriptor expert merely because the wallet software changed the representation of an already-valid private key.

`bitcoin-utilities` provides that missing bridge.