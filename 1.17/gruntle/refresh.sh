# updates version for dependencies on maven.vram.io
# args
# 1 - name of the dependency as it would appear in gradle, like io io.vram:bitkit
#     if it is version-specific, name should include those tags, like io.vram:frex-fabric-mc117
# 2 - path to target .gradle file, relative to project root folder
#     should generally start with fabric/ forge/ or quilt/
updateVersion()
{
  if grep -q $1 $2; then
    subUrl=${1//[:\.]/\/}
    ver=$(curl -s https://maven.vram.io/io/vram/bitkit/maven-metadata.xml | grep "<release>" | sed -n 's:.*<release>\(.*\)</release>.*:\1:p')
    echo "Lastest version of $1 is $ver"
    sed -i '' "s/$1:[0-9\.]*/$1:$ver/" $2
  fi
}

updateVersion io.vram:bitkit fabric/project.gradle

sed -i '' 's/"fabricloader": ".*"/"fabricloader": ">=0.12.5"/' fabric/src/main/resources/fabric.mod.json
sed -i '' 's/"minecraft": ".*"/"minecraft": "1.17.1"/' fabric/src/main/resources/fabric.mod.json
