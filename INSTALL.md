# Install superloop

<details>
<summary><strong>Claude Code</strong></summary>

### Install

```bash
claude plugin marketplace add cskwork/superloop
claude plugin install superloop@superloop
```

Type `/superloop`.

### Verify

```bash
claude plugin list
```

### Update

```bash
claude plugin marketplace update superloop
```

### Uninstall

```bash
claude plugin uninstall superloop
claude plugin marketplace remove superloop
```

</details>

<details>
<summary><strong>Codex</strong></summary>

### Install

```bash
codex plugin marketplace add cskwork/superloop --ref main
codex plugin add superloop@superloop
```

Type `$superloop`.

### Verify

```bash
codex plugin list
```

### Uninstall

```bash
codex plugin remove superloop
codex plugin marketplace remove superloop
```

</details>

<details>
<summary><strong>Gemini CLI</strong></summary>

### Install (extension, always-on)

```bash
gemini extensions install https://github.com/cskwork/superloop
```

### Install (command, opt-in)

```bash
mkdir -p ~/.gemini/commands
curl -fsSL https://raw.githubusercontent.com/cskwork/superloop/main/skills/superloop/agents/gemini.toml \
  -o ~/.gemini/commands/superloop.toml
```

Type `/superloop` in a new session.

### Verify

```bash
gemini extensions list
```

### Uninstall

```bash
gemini extensions uninstall superloop
```

</details>

<details>
<summary><strong>Cursor, OpenCode, Amp, and other agent-skills harnesses</strong></summary>

### Install

```bash
npx skills add cskwork/superloop
npx skills add cskwork/superloop -g
```

Type `/superloop` in a new agent chat.

### Verify

```bash
npx skills list
```

### Update

```bash
npx skills update superloop
```

### Uninstall

```bash
npx skills remove superloop
```

</details>

<details>
<summary><strong>Antigravity (agy)</strong></summary>

### Install

```bash
agy plugin install https://github.com/cskwork/superloop
```

### Verify

```bash
agy plugin list
```

### Uninstall

```bash
agy plugin uninstall superloop
```

</details>
