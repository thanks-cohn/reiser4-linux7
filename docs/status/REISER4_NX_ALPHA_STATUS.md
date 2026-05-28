# Reiser4-NX Developer Alpha Status

Houston.

You’re not going to believe this shit.

We got movement.

Reiser4 is alive again on Ubuntu 24.04 and Linux 6.8. Barely. Coughing violently. Covered in wires and mystery fluids. But alive.

Current status from deep space:

- `reiser4.ko` builds
- module loads
- VFS handshake successful
- `mkfs.reiser4` operational
- mount successful
- file creation successful
- read/write operational
- strange noises detected from ancient directory structures
- crew morale unexpectedly high

At approximately 04:38 UTC the filesystem successfully touched a file for the first time in years without immediately exploding into cosmic dust.

We stared at the terminal for a while after that one.

Not because it was technically impressive.

But because somewhere underneath all the warnings, stack traces, forgotten assumptions, compiler drift, dead mailing lists, and old code written by people who probably never imagined Linux 6.x...

something answered back.

Current smoke test:

```bash
make -C /lib/modules/$(uname -r)/build M=$PWD CONFIG_REISER4_FS=m modules

./scripts/reiser4-alpha-smoke-test.sh
```

WARNING:

If you store real data on this and your machine opens a portal to 2004, don't take it up with me. 
Use VMs.
Use disposable images.
Do not taunt the filesystem.

End transmission.

Signal strength improving.
