git branch heroku
git checkout heroku

mv .www/* ./
rm -rf ./www
rm -rf ./game
git add -A
git commit -m
git push origin heroku
git push heroku heroku:master

