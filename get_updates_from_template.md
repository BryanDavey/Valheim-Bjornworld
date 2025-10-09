# Instructions for how to pull updates from template repo

```bash
git remote add template git@github.com:BryanDavey/Valheim-Modded.git
git fetch --all
# If there are changes on the template, you can merge them in with the following command:
git merge template/main --allow-unrelated-histories -m "Merge updates from template repo"
git push
```
