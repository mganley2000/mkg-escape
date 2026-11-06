# Escape the Depths

A 2D side-on dungeon climber built with **Godot 4.7 + GDScript** on the **Compatibility** renderer,
so it runs on desktop and in the browser (WebAssembly).

You wake on the lowest of 200 floors. Climb ladders and stairs, kill everything in one hit, scavenge
weapons, ammo, food and potions, and reach the surface. Gloomy dungeon music plays while you explore
and swells into a heavier combat layer when monsters hunt you.

## Running

1. Install Godot 4.7.x (standard, not .NET): `winget install GodotEngine.GodotEngine`
2. Open `project.godot` in the editor and press **F5**, or from a shell:

   ```powershell
   godot --path .
   ```

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | A / D, arrows | Left stick, D-pad |
| Climb ladders / stairs | W / S, up / down | Left stick, D-pad |
| Jump | Space | A |
| Attack / fire | J, Ctrl, left click | X |
| Switch weapon | Q / E, 1-7 | LB / RB |
| Zoom | Mouse wheel, + / - | |
| Pause | Esc, P | Start |

Debug builds only: **F1** gives every weapon, **F2** teleports up 10 floors.

## Project layout

```
data/        weapon and monster .tres resources (tweak balance here)
scripts/
  autoload/  Events bus, GameState, Controls, Database, SpriteLib, ArtLib, Audio
  core/      constants, name generator
  world/     seeded floor generation, persistent FloorData, chunk streaming, walls, props, torches
  actors/    player, monsters, sprite helpers
  combat/    projectiles, explosions, blood, effects
  game/      game scene, camera, parallax layers
  ui/        menu, HUD, pause/end overlay
shaders/     palette (tints, hit flash), vignette
tests/       headless world-generation test
```

Levels are generated deterministically from the run seed. A floor is built the first time it comes
into view and its state (kills, blood, dropped loot) is kept for the rest of the run.

## Testing

```powershell
# headless world-gen determinism / connectivity test
godot --headless --path . -s tests/test_worldgen.gd

# sound banks and music streams
godot --headless --path . -s tests/test_audio.gd

# scripted visual smoke test; screenshots land in .screens/
godot --path . -- --autoshot
```

## Exporting

Install the 4.7.2 export templates (Editor > Manage Export Templates), then:

```powershell
godot --headless --path . --export-release "Windows Desktop" build/windows/mkg-escape.exe
godot --headless --path . --export-release "Web" build/web/index.html
```

The Web preset is single-threaded, so it needs no special COOP/COEP headers and works on any static
host. To test locally: `python -m http.server 8060 --directory build/web` and open
<http://localhost:8060>.

Keep an empty `build/.gdignore` so Godot does not import exported files.

## Credits

See [`assets/CREDITS.md`](assets/CREDITS.md).
