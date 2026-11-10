# Tests

This is a development-only test source set, separate from `addons/asset_placer/`.
It is not part of the addon directory distributed as the plugin. Production scripts
must not depend on these tests or gdUnit4.

## Recycler view and asset-library tests

Requirements: Godot and the installed `addons/gdUnit4/` development dependency.
Run from the repository root. For a fresh checkout, import first to register script
classes:

```sh
godot --headless --editor --import --path .
```

Run the reusable recycler and asset-library integration suites:

```sh
godot --headless --path . \
  --script addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --ignoreHeadlessMode \
  -a res://tests \
  -rd res://.godot/recycler_view_reports
```

Use `-a res://tests/recycler_view` for only the reusable component, or
`-a res://tests/asset_library` for the real preview/settings integration.

The library suites cover responsive HFlow-compatible columns, `ui_scale` and theme
minimums, real settings notifications, selected asset IDs across reuse/sort/filter
updates, current click/context targets, stale-click rejection, and pooled thumbnail
cleanup. They use nonexistent asset paths and in-memory services: no editor settings,
thumbnail files, or render jobs are created. Scene wiring is inspected as serialized
text rather than initializing the full editor window and its services headlessly.

Reports stay under the already-ignored `.godot/` directory. The component suites cover layout
geometry, adapter/holder contracts, and the native-scrolling RecyclerView, including
`@onready` children, bounded view creation, reuse, resize, native scroll clamping,
notifications, adapter replacement, and teardown. These tests set scrollbar values
and emit signals directly; they do not simulate input. Actual pointer, wheel, and
keyboard interaction should be checked windowed, not through headless simulation.
