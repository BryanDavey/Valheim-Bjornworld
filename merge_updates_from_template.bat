@echo off
git fetch --all
git merge template/main --allow-unrelated-histories -m "Merge updates from template repo"
git push