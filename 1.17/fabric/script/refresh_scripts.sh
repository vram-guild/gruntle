echo 'Checking for build script updates...'

curl -s https://maven.vram.io/io/vram/canvas-fabric-mc117/maven-metadata.xml | grep "<release>" | sed "s/.*<release>\([^<]*\)<\/release>.*/\1/"
