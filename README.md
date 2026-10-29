# Teach Together: Math Quest

A co-op Roblox adventure where kids **teach each other math** to move through the world together.

## How it plays

The world is a path of zones: **Grouping Grove → Fraction Falls → Garden of Shapes → Place Value Peaks → Treasure Room**.

In every zone:

1. **Each player becomes an expert.** The game gives you a glowing lesson stone in your color. Only *you* can read it, and it teaches you one math idea.
2. **Each player gets a challenge on a *different* idea**, one that a teammate learned and you didn't.
3. **Teach each other.** Experts explain their idea, and can put a worked example on the zone's big chalkboard. Stuck? Press **🙋 Ask for help** and your expert gets a message.
4. **Solve 2 problems in a row** at the yellow **Challenge Gate** to master your idea.
5. **The gate opens only when *everyone* is done**, so the whole team crosses the bridge together.

Problems are made up fresh every time, so the expert can't just say the answer. They have to teach *how*.

| Zone | Concepts |
|---|---|
| Grouping Grove | Equal Groups (multiplication), Fair Sharing (division) |
| Fraction Falls | Parts of a Whole, Comparing Fractions |
| Garden of Shapes | Area, Perimeter |
| Place Value Peaks | Place Value, Rounding |

**Players:** best with 2–4. With 2 players, each teaches the other. With 3 or more, some kids share an expertise, and anyone can help anyone. Playing alone (handy for testing) gives you every lesson. If someone leaves mid-zone and nobody else knows their idea, the stone opens up for whoever needs it, so nobody gets stuck.

## Setting it up

The whole world is built by code, so there's nothing to place by hand.

### Option A: copy and paste (no extra tools)

1. Open **Roblox Studio** and create a new **Baseplate** game. (The script removes the baseplate for you.)
2. In the **Explorer**:
   - Under **ReplicatedStorage**, add a **Folder** named `Shared`. Inside it, add three **ModuleScripts** named `Config`, `Concepts` and `Assignments`, and paste in the matching files from `src/shared/`.
   - Under **ServerScriptService**, add a **Folder** named `Server`. Inside it, add a **Script** named `Main` (paste `src/server/Main.server.lua`) and a **ModuleScript** named `WorldBuilder` (paste `src/server/WorldBuilder.lua`).
   - Under **StarterPlayer → StarterPlayerScripts**, add a **LocalScript** named `Main` and paste in `src/client/Main.client.lua`.
3. Press **Play**.

### Option B: Rojo (if you like editing in VS Code)

```bash
rojo serve        # then click "Connect" in the Rojo Studio plugin
# or build a place file:
rojo build -o MathQuest.rbxl
```

### Testing with more than one player

In Studio: **Test** tab → **Clients and Servers** → choose **2 Players** → **Start**. Two player windows open, so you can play both sides.

### Playing together for real

**File → Publish to Roblox**. Then in **Game Settings → Permissions**, keep the game **Private** (or Friends-only) and invite your kids' accounts. Roblox limits chat for younger players, so this works best when the kids are in the same room or on a call together. Talking out loud is the whole point!

## Make it your own (great for kids!)

- **`src/shared/Config.lua`**: rename zones, change colors, choose which concepts go in each zone, and set how many problems you need to get right.
- **`src/shared/Concepts.lua`**: every lesson, example, teaching tip and problem generator. To invent a new concept, copy one `define(...)` block, give it a new id, write the lesson, and add the id to a zone in `Config.lua`. Ideas: telling time, money, odd and even, skip counting, patterns.

Difficulty lives in each concept's `generate` function. For example, `rng:NextInteger(2, 6)` picks numbers from 2 to 6.

## How the code is organized

```
src/
  shared/              (ReplicatedStorage.Shared — used by server and players)
    Config.lua         zones, colors, rules
    Concepts.lua       lessons + problem generators + answer checking
    Assignments.lua    who learns what, who solves what
  server/              (ServerScriptService.Server)
    Main.server.lua    game rules: zones, gates, answers, help requests
    WorldBuilder.lua   builds the zones, stones, gates, bridges and treasure room
  client/              (StarterPlayerScripts.Client)
    Main.client.lua    mission panel, team panel, lessons, problems, messages
```

Answers are checked on the server, and each player only ever receives their own problem.
