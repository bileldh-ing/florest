# florest

A two-screen plant-shop UI (Top picks + Plant detail) cloned from the reference
shot, with springy micro-animations and gestures. Flutter, Dart 3, Riverpod.

## Setup

```bash
# 1. Generate the Android/iOS platform folders (lib/, assets/, pubspec stay as-is)
flutter create . --platforms=android,ios --project-name florest --org com.florest

# 2. Packages
flutter pub get

# 3. Run (use profile mode to judge smoothness)
flutter run            # debug
flutter run --profile  # performance check
flutter analyze
```

The repo already ships 16 procedural top-down plant cut-outs in
`assets/plants/`, so it runs immediately, offline.

## Real plant photos (dev-time, once)

```bash
pip install pillow requests rembg
export PIXABAY_KEY=xxxx        # optional, free key: pixabay.com/api/docs
python3 tool/fetch_images.py --force
```

The fetcher searches Pixabay (if a key is set) and Wikimedia Commons with the
brief's search terms, removes backgrounds with `rembg`, trims padding, resizes
to ≤1024 px, saves WebP q90 and rewrites `CREDITS.md`. Anything it can't find
falls back to `tool/gen_placeholders.py`. Check the results by eye: a search
can't guarantee a true bird's-eye angle. To swap one by hand, drop a
transparent PNG/WebP with the same file name into `assets/plants/`.

## Gestures

| Where | Gesture | Result |
|---|---|---|
| Card | Tap | Circular reveal + Hero flight to detail |
| Card | Long press | Care quick-peek sheet + haptic tick |
| `+` | Tap | Spins to ✓, plant arcs into the bag, badge bumps, undo snackbar |
| List | Swipe left/right | All / Outdoor / Indoor (follow-finger PageView) |
| List | Scroll / pull down | Header collapses with parallax / stretches and snaps back |
| Rail or big plant | Swipe up/down | Next / previous plant, notch glides on a spring |
| Big plant | Drag in a circle | Rotates with inertia, idle spin continues |
| Big plant | Pinch | Zoom 1–1.6×, springs back |
| Detail | Swipe from left edge / Back | Reverse Hero to home |

## Structure

```
lib/
  main.dart                     app + shared idle-rotation ticker
  core/theme.dart               colours, radii, text styles, spring
  core/assets.dart              image provider + precache helper
  data/plant.dart, plants_repo.dart
  state/providers.dart          filter, selected plant, bag (Riverpod)
  features/home/…               home_screen, hero_header, filter_tabs, plant_card, add_button, care_sheet
  features/detail/…             detail_screen, side_rail, notch_painter, plant_info
  widgets/…                     plant_image, rotating_plant, care_icon_chip, bag_button,
                                round_icon_button, fly_to_bag, reveal_route, screen_frame
tool/fetch_images.py, tool/gen_placeholders.py
```

## Assumptions

- Counts: 16 plants = 8 outdoor + 4 indoor + 4 "both". The Outdoor/Indoor tabs
  show only that exact type (so the badges read 16 / 8 / 4 like the reference);
  "both" plants appear under All.
- Images are `.webp` (the brief's pipeline exports WebP), not `.png`.
- The rail is ~34% of width and the card offset ~66 pt, measured from the
  screenshot rather than the brief's 26% / 90 pt, since the brief asks to match
  the screenshot exactly.
- The 40 pt rounded screen clip is on (`ScreenFrame(clipCorners: true)`); turn it
  off for edge-to-edge on real devices.
- Device-tilt parallax (optional, `sensors_plus`) is not included to keep the
  dependency list minimal.
- Inter is loaded by `google_fonts` at runtime (system sans until it arrives).
  To bundle it offline, add the TTFs and set `GoogleFonts.config.allowRuntimeFetching = false`.
- Hero tags are scoped per tab so two tabs never share one.
