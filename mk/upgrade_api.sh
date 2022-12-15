#!/bin/bash

set -e

git stash
git checkout main
git pull

$(git config core.editor) api.tf

make terraform_init
make terraform_apply

echo "Commit 🚀️"
git add -p
git commit -m "Upgrade api module"
git status

echo "Do you want to push?(y/n)"
read -r push

if [ "$push" == y ]
  then
    git push
fi

echo "Test in staging"
firefox api.serlo-staging.dev/___graphql

echo "If everything is OK, notify your frontend colleagues"
echo "Take a look at the changelogs for that"
firefox https://github.com/serlo/api.serlo.org/blob/main/CHANGELOG.md
firefox https://github.com/serlo/serlo.org-database-layer/blob/main/CHANGELOG.md

git stash pop
