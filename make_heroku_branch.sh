set -e

cd gamerist

git checkout master

rm -rf /tmp/heroku_branch_script
mkdir /tmp/heroku_branch_script
cp -R ./* /tmp/heroku_branch_script/

git checkout heroku
rm -rf *
cp -R /tmp/heroku_branch_script/www/* ./

git add -A
read -p "Please add a commit message: " herokucmes
git commit -m"$herokucmes"
git push origin heroku
# git push heroku heroku:master

rm -rf /tmp/heroku_branch_script
git checkout master
echo "Checkout complete. You should now see the master branch."
