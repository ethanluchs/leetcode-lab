# LeetCode Lab

Practice LeetCode problems in Python with real tests, inside one small
container. No ports, no services, and it works offline once built.

## Setup

You need **Docker Desktop** and **VS Code** installed.

1. **Start Docker Desktop** and wait until it says it's running (whale icon
   in the taskbar/menu bar stops animating).

2. **Install the Dev Containers extension** in VS Code: open the Extensions
   view (`Ctrl+Shift+X`, or `Cmd+Shift+X` on Mac), search **Dev Containers**,
   and install the one by Microsoft.

3. **Get the code** into a normal folder, *not* inside OneDrive, iCloud or
   Dropbox:

   ```bash
   git clone https://github.com/ethanluchs/leetcode-lab.git
   ```

   No git? On the GitHub page click **Code → Download ZIP** and unzip it.

4. **Open the `leetcode-lab` folder in VS Code** (**File → Open Folder…**).

5. **Reopen in Container.** Click **Reopen in Container** in the pop-up at the
   bottom right. If you missed it, press `F1`, type
   `Dev Containers: Reopen in Container`, and press Enter.

   The first time takes a minute or two while the container builds.

6. **Check it works.** Open a terminal in VS Code (**Terminal → New
   Terminal**). It opens *inside* the container. Run:

   ```bash
   cd leetcode/two_sum
   pytest -q
   ```

   You should see `15 failed`. That's correct: you haven't solved it yet.

You're set up. Next time, just open the folder in VS Code and it reconnects
to the container automatically.

### Terminal only (no VS Code)

```bash
docker compose build          # ~1 min, once
docker compose run --rm lab   # opens a shell in the container
```

You're now in `/work`, which is the same folder as `./work` on your machine.
Edit files in any editor and run tests in the container. `exit` leaves; your
work stays in `./work`.

### If something goes wrong

| Symptom | Fix |
| --- | --- |
| `error during connect`, "pipe", "daemon", or `500 Internal Server Error` | Docker Desktop isn't running or got stuck. Quit it fully and start it again. |
| `cp: cannot create directory '/work/leetcode': Permission denied` (Linux) | See *Linux* under Instructor notes below. |
| No "Reopen in Container" option | The Dev Containers extension isn't installed (step 2). |

## The loop

```bash
cd leetcode/two_sum
cat README.md          # the problem statement
# ... edit solution.py ...
pytest -q              # red -> green
```

Each problem folder contains:

| File | What it's for |
| --- | --- |
| `README.md` | problem statement, difficulty, topics |
| `solution.py` | **the only file you edit** |
| `test_solution.py` | the test cases. This is the contract |
| `helpers.py` | readable assertion output |
| `__init__.py` | package marker |

**Don't edit the tests to make them pass.** They include the LeetCode
examples plus edge cases, so green here really means green.

A few cases pass before you've written anything (an empty stub happens to
return the right answer for some inputs). Only all-green counts.

## Useful pytest flags

```bash
pytest -q              # quiet
pytest -x              # stop at the first failure
pytest -k nums0        # only cases whose id contains "nums0"
pytest -s              # show printed output
pytest                 # from /work: every problem, every case
```

## Looking at data structures

```python
from leetcode_py import TreeNode, ListNode

root = TreeNode.from_list([3, 9, 20, None, None, 15, 7])
print(root)
# 3
# ├── 9
# └── 20
#     ├── 15
#     └── 7

print(ListNode.from_list([1, 2, 3]))
# 1 -> 2 -> 3
```

---

## Instructor notes

Measured on Windows 11 + Docker Desktop 27.4 (WSL2), 2026-10-06.

| | |
| --- | --- |
| Cold build (`--no-cache`, incl. pulling `python:3.12-slim`) | 46 s |
| Image size | 337 MB (340 MB with Grind 75) |
| `docker save \| gzip` | 80 MB |
| `devcontainer up` with the image already built | 23 s |

### Smoke test before the session

```bash
docker compose build
docker compose run --rm lab bash -c '
  lcpy --help >/dev/null && echo "lcpy OK" &&
  python -c "import pytest; print(\"pytest\", pytest.__version__)" &&
  ls leetcode &&
  cd leetcode/two_sum && pytest -q 2>&1 | tail -n 1'
```

Expect `15 failed`, because the stubs are unimplemented. Run
`docker compose run --rm lab true` twice: the first run prints
"First run -- seeding", the second prints nothing.

Expected noise: the build prints `Found 11 errors (11 fixed, 0 remaining)`.
That's ruff auto-formatting the generated files, not a failure.
`devcontainer up` prints `Error fetching image details: No manifest found`,
which is also harmless.

### Hand out a prebuilt image

Campus Wi-Fi is the usual failure point. Build once, then share the file:

```bash
docker save leetcode-lab:1.0 | gzip > leetcode-lab.tar.gz      # ~80 MB
```

Students run `docker load -i leetcode-lab.tar.gz`, after which both options
above use the loaded image instead of building.

### Linux

The container runs as uid 1000, which is the first user on almost every Linux
laptop, so most Linux students need nothing extra. macOS and Windows (Docker
Desktop) never need anything extra.

If a Linux student's `id -u` isn't 1000 (shared or university-managed
machines), the first run fails with
`cp: cannot create directory '/work/leetcode': Permission denied`.
Run as their own uid instead:

```bash
docker compose run --rm --user "$(id -u):$(id -g)" lab
```

The prompt then shows `I have no name!`, which is cosmetic; tests and edits
work normally.

`work/` is committed (via `work/.gitkeep`) on purpose. If it's missing, Docker
creates it owned by root and the first run fails with the same error even
for uid 1000. Fix: `sudo rm -rf work && mkdir work`.

Tested with Docker Desktop's WSL2 integration (Ubuntu 24.04), which passes
uids through like native Docker Engine. Not tested on a native Linux install.

### Picking the problem set

Default: Two Sum (1), Valid Parentheses (20), Best Time to Buy and Sell Stock
(121), Valid Palindrome (125), Invert Binary Tree (226).

Change it with the `GEN_ARGS` build arg in `compose.yaml`:
`-t grind-75` (75 problems), `-t blind-75` (75), `-t neetcode-150` (150),
`-d Easy`, `-s two_sum`, or `--all`. The package bundles 1,404 problems.

### Teaching angles

- **Build time vs run time.** `lcpy gen` runs in a `RUN` layer, while seeding
  runs in the entrypoint. Ask why before explaining.
- **Layer caching.** Uncomment the Graphviz block in the Dockerfile and
  rebuild: everything after it rebuilds. Move it to the bottom and rebuild
  again: the earlier layers come from cache.
- **Image vs bind mount.** Delete `./work/leetcode` and rerun: the problems
  come back from the image. Delete the image: your work is still in `./work`.
- **No network.**
  `docker run --rm -it --network none -v "$PWD/work:/work" leetcode-lab:1.0`
  still runs every test.
- **`run` vs `up`.** This is an interactive shell, not a long-running service,
  so it's `compose run --rm`, not `compose up`.
