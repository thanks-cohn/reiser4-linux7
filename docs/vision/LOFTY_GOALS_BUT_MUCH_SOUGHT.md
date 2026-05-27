# Lofty Goals but Much Sought

## The Reiser4-Linux7 Vision

Reiser4 was never merely a filesystem.

It was an attempt to rethink storage itself.

Years later, much of the surrounding ecosystem changed:
Linux internals evolved, kernel APIs shifted, VFS models transformed, memory management migrated toward folios, and many once-stable interfaces disappeared.

Yet the central ideas inside Reiser4 still feel strangely modern.

This project exists because those ideas deserve survival.

---

# The Goal

The immediate goal is straightforward:

- Bring Reiser4 to modern Linux 7.x kernels
- Restore buildability
- Restore mountability
- Restore operational trust
- Preserve compatibility wherever possible

But the long-term goal is larger.

The vision is for filesystems to become:

- modular
- inspectable
- survivable
- portable
- adaptable
- understandable
- durable across decades

The storage engine should outlive platform APIs.

---

# Why This Matters

Modern computing increasingly depends on enormous quantities of:

- media
- datasets
- metadata
- sidecar information
- archives
- image collections
- AI corpora
- creative assets
- persistent identity systems

Yet many filesystems remain fundamentally shaped by assumptions from earlier eras.

Reiser4 explored ideas that still feel ahead of their time:

- plugin-based architecture
- flexible storage behavior
- metadata-rich structures
- advanced balancing
- modular policies
- dynamic internal organization

The tragedy was not lack of innovation.

The tragedy was survivability.

---

# The Philosophy

This project does not seek novelty for novelty’s sake.

A filesystem should not feel unstable or experimental to its users.

Infrastructure earns trust through:

- predictability
- recoverability
- explainability
- operational clarity
- durability
- boring behavior under pressure

The internals may be sophisticated.

The experience should feel calm.

The ideal outcome is not:
“this filesystem is crazy.”

The ideal outcome is:
“why doesn’t everything work like this?”

---

# Reiser4-Linux7

The current effort focuses on restoring and modernizing Reiser4 for modern Linux kernels.

This includes:

- folio migration
- BIO modernization
- VFS modernization
- idmapped mount compatibility
- writeback compatibility
- inode state modernization
- fs_context migration
- Linux 7 kernel compatibility

Compatibility layers are being introduced to reduce future breakage and isolate unstable kernel-facing APIs.

---

# Beyond Porting

The long-term architectural direction explores a future where Reiser4 evolves into a more durable structure:

- stable core logic
- thinner platform adapters
- reduced dependency gravity
- cleaner compatibility boundaries
- survivable long-term architecture

Potential future directions include:

- Linux adapter layers
- FUSE integration
- Windows integration
- userspace tooling
- recovery tooling
- filesystem-native metadata systems
- portable storage engine architecture

---

# A Filesystem People Can Build Upon

The aspiration is ambitious.

The goal is not merely for Reiser4 to survive,
but to become something people feel comfortable building upon again.

Not because it is fashionable.

Not because it is flashy.

But because it is dependable.

Because it is understandable.

Because it is modular.

Because it remains inspectable.

Because its architecture encourages longevity rather than decay.

The ideal is not just a filesystem.

The ideal is a durable storage foundation.

A platform.

A language for future systems.

---

# Lofty Goals but Much Sought

The scale of these ambitions is understood.

Many projects begin with grand visions and disappear.

Real infrastructure is earned slowly:

- patch by patch
- build by build
- mount by mount
- recovery by recovery

This project is still early.

Some compatibility paths are temporary.
Some modernizations remain incomplete.
Some interfaces are transitional.

But the direction is intentional.

The work continues.

And the goal remains clear:

Advanced internals.
Conservative operations.
Long-term survivability.
Infrastructure people can trust.
