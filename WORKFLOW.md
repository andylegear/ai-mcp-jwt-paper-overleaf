# Overleaf / GitHub Sync Workflow

This paper directory (`c:\dev\aiMcpResearch\paper`) is a git repo with two remotes:

- `origin`  → https://github.com/andylegear/ai-mcp-jwt-paper-overleaf.git (backup / history)
- `overleaf` → https://git.overleaf.com/6a9194e66024859e11020cb2 (live collaborative editor)

## Everyday workflow

**After editing locally (VS Code):**
```powershell
cd C:\dev\aiMcpResearch\paper
git add -A
git commit -m "Describe your change"
.\scripts\sync-overleaf.ps1 run
```
This pulls from GitHub, pulls from Overleaf, merges, then pushes to both. Refuses to run if your
working tree has uncommitted changes or if there's an unresolved merge conflict — resolve those
manually first.

**After editing on Overleaf (web editor) and want it locally:**
```powershell
cd C:\dev\aiMcpResearch\paper
git pull --no-rebase overleaf main
```
Then continue editing locally, commit, and run the sync script again to push back to both remotes.

## Manual equivalent (no script)

```powershell
git pull --no-rebase origin main
git pull --no-rebase overleaf main
git push origin main
git push overleaf main
```

## Authentication

Git's credential manager handles the Overleaf git token automatically (cached from prior use). If
it ever expires or prompts, get a fresh git access token from the Overleaf project: **Menu → Git**.

## Handing over Overleaf ownership (e.g. to Jim Buckley)

- Safe to do. The project ID (`6a9194e66024859e11020cb2`) and git remote URL do **not** change when
  ownership transfers to another paid-plan collaborator.
- Each collaborator authenticates with their **own** Overleaf git token — Jim will need to set up
  his own local clone/remote and authenticate separately; he does not reuse your cached credential.
- Your existing `overleaf` remote keeps working as long as you remain a collaborator with edit access.

## Conflicts

If `sync-overleaf.ps1 run` reports unresolved merge conflicts, resolve them in the affected files,
then:
```powershell
git add <resolved files>
git commit
.\scripts\sync-overleaf.ps1 run
```
