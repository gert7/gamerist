set -e

git checkout master

rm -rf /tmp/gameristwww
cp -R www /tmp/gameristwww

git checkout heroku
rm -rf *
cp -R /tmp/gameristwww/** .

cd www
RAILS_ENV=production bundle exec rake assets:precompile
cd ..

git add -A
read -p "Please add a commit message: " herokucmes
git commit -m"$herokucmes"
git push origin heroku
# git push heroku heroku:master

rm -rf /tmp/gameristwww
git checkout master
echo "Checkout complete. You should now see the master branch."

