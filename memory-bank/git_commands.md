# Git Commands Reference

This file contains useful Git commands for working with the C++ Development Environment Setup project.

## Viewing Staged Changes

To view changes that have been staged but not yet committed:

```bash
git --no-pager diff --staged
```

This command shows the differences between the staging area and the last commit. The `--no-pager` option ensures the output is displayed directly in the terminal without using a pager program like `less`.

### When to Use

- Before committing, to review what changes will be included in the commit
- To verify that the correct changes have been staged
- To create detailed commit messages based on the actual changes

### Example Output

```diff
diff --git a/build_cpp_dev_env.sh b/build_cpp_dev_env.sh
index f1d4ba3..381b4cd 100755
--- a/build_cpp_dev_env.sh
+++ b/build_cpp_dev_env.sh
@@ -470,7 +470,7 @@ if [ "$DO_SETUP" = true ]; then
 
     # Install basic development tools
     echo "Installing build-essential, git, mc, htop..."
-    sudo apt install -y build-essential gdb git mc htop python3-pip curl gnupg lsb-release ca-certificates gettext
+    sudo apt install -y build-essential gdb git mc htop python3-pip curl gnupg lsb-release ca-certificates gettext nano
 
     # Install Docker from the official Docker repository
     echo "Installing Docker from the official Docker repository..."
```

## Other Useful Git Commands

### Viewing Commit History

```bash
git log
```

### Viewing Changes in Working Directory

```bash
git diff
```

### Viewing Changes for a Specific File

```bash
git diff -- path/to/file
```

### Viewing Changes Between Commits

```bash
git diff commit1..commit2
```
