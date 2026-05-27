# reiser4-nx

A long-term modernization and survivability effort for Reiser4.

## Philosophy

The filesystem core should outlive platform APIs.

Linux, Windows, FUSE, and future platforms should become replaceable adapter layers surrounding a durable storage engine.

## Goals

- Portable C-first filesystem core
- Thin platform adapter layers
- Long-term survivability
- Reduced dependency gravity
- Modern Linux compatibility
- Future Windows support
- Future FUSE/userspace support
- Recoverable architecture
- Inspectable infrastructure

## Architecture Direction

reiser4-nx/

    core/
        storage engine
        trees
        allocation
        journaling
        plugins

    platform/
        linux/
        windows/
        fuse/

    tools/
        mkfs
        fsck
        inspectors
        recovery

    compat/
        kernel compatibility shims

    docs/
        architecture
        migration
        design

## Current State

The current effort is focused on:

- Linux 7 kernel compatibility
- VFS modernization
- folio migration
- idmapped mount compatibility
- filesystem survivability architecture

## Principle

Platform APIs are temporary.

Filesystem ideas can survive decades if the architecture allows them to.
