set -e

mv ./www/* ./
rm -rf ./www

git add -A
read -p "Please add a commit message: " herokucmes
git commit -m"$herokucmes"
git push origin heroku
git push heroku heroku:master

