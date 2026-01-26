# Scripts

## DMG build (no Finder automation)

This uses a saved `.DS_Store` layout so the DMG can be built without Finder
automation permissions.

1) Create the layout template (one-time):

```bash
scripts/create_dmg_template.sh "build/Build/Products/Release/Leaf.app"
```

Arrange the Finder window, close it, then press Enter in Terminal.

2) Build the DMG using the template:

```bash
scripts/build_dmg.sh --template "build/Build/Products/Release/Leaf.app" "Leaf-$(date +%Y%m%d-%H%M%S).dmg"
```

Template files are stored in `scripts/dmg_template/`.

To avoid Finder caching while iterating, use a unique volume name:

```bash
scripts/build_dmg.sh --template --volname "Leaf Installer $(date +%H%M%S)" "build/Build/Products/Release/Leaf.app" "Leaf-$(date +%Y%m%d-%H%M%S).dmg"
```

Manual layout (no Finder automation, no template):

```bash
scripts/build_dmg.sh --manual --volname "Leaf Installer $(date +%H%M%S)" "build/Build/Products/Release/Leaf.app" "Leaf-$(date +%Y%m%d-%H%M%S).dmg"
```

Manual layout (use script default timestamped output):

```bash
scripts/build_dmg.sh --manual --volname "Leaf Installer $(date +%H%M%S)" "build/Build/Products/Release/Leaf.app"
```

During manual mode:

1) Finder opens the mounted DMG.
2) Switch to Icon View and set icon size (Cmd+J).
3) Optional: set background to the provided PNG at `.background/background.png`.
4) Arrange `Leaf` and `Applications`, then close the window.
5) Press Enter in Terminal to finalize the DMG.

To force Finder automation (if desired):

```bash
scripts/build_dmg.sh --finder "build/Build/Products/Release/Leaf.app"
```
