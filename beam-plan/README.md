# beam-plan

Project: **ii-halos**, the owner's fork of ii-vynx (`github.com/JANO-de/ii-halos`), used by `pkgs/ii-vynx`.
Goal: add p3drovfx-style features to vynx **from scratch**, small and fast. No bulk port of p3drovfx.
Director: Claude · Executor: **Beam** · Owner: user (also the junior learning QML; explain briefly, never lecture).

| File | Purpose |
|------|---------|
| `guidelines.md` | rules. Read first, fully |
| `steps.md` | ordered build steps with exact files, commands, checks |
| `todo.md` | checklist. Update after every step |
| `roadmap.md` | phases and the order of features |
| `ask-first.md` | questions to ask the owner before each step |
| `prompt-jarvis.md` | prompt for the senior (Jarvis/Claude) |
| `prompt-beam.md` | prompt for the junior (Beam) |
| `notes/` | scratch notes per step (delete when closed) |

Repo-wide Nix rules (build never switch, hashes, pins, git): `../beam-plans/README.md`. Both apply; on conflict, stricter wins.
Start: read `guidelines.md`, `todo.md`, then run `ask-first.md` for the next open step.
