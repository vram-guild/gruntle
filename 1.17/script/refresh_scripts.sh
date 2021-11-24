echo 'Checking for build script updates...'
# delete gruntle repo folder if exists from aborted run
if [ -d "gruntle-master" ]; then
  rm -rf gruntle-master
fi

curl https://github.com/vram-guild/gruntle/archive/refs/heads/master.zip -O -J -L
unzip gruntle-master
cp -R gruntle-master/1.17/ .
rm -rf gruntle-master
rm gruntle-master.zip
