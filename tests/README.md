# Tests

This is a development-only test source set, separate from `addons/asset_placer/`.
It is not part of the addon directory distributed as the plugin. Production scripts
must not depend on these tests or gdUnit4.


## Recycler view tests

Requirements: Godot and the installed `addons/gdUnit4/` development dependency.
Run from the repository root. For a fresh checkout, import first to register script
classes:

```sh
godot --headless --editor --import --path .
```

Run only the recycler component suites:

```sh
godot --headless --path . \
  --script addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --ignoreHeadlessMode \
  -a res://tests/recycler_view \
  -rd res://.godot/recycler_view_reports
```

Reports stay under the already-ignored `.godot/` directory. The suites cover layout
geometry, adapter/holder contracts, and the native-scrolling RecyclerView, including
`@onready` children, bounded view creation, reuse, resize, native scroll clamping,
notifications, adapter replacement, and teardown. These tests set scrollbar values
and emit signals directly; they do not simulate input. Actual pointer, wheel, and
keyboard interaction should be checked windowed, not through headless simulation.
