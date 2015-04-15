set -e

git checkout master

rm -rf ../gameristh/**
cp -r www/** ../gameristh/.

cd ../gameristh

git add -A
read -p "Please add a commit message: " herokucmes
git commit -m"$herokucmes"
git push heroku master
# git push heroku heroku:master

cd ../gamerist
echo "Checkout complete. You should now see the master branch."

