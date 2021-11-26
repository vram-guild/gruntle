# updates version for dependencies on maven.vram.io
# args
# 1 - name of the dependency as it would appear in gradle, like io.vram:bitkit
#     if it is version-specific, name should include those tags, like io.vram:frex-fabric-mc117
# 2 - path to target .gradle file, relative to project root folder
#     should generally start with fabric/ forge/ or quilt/
updateVersion()
{
  if grep -q $1 $2; then
    subUrl=${1//[:\.]/\/}
    ver=$(curl -s "https://maven.vram.io/$subUrl/maven-metadata.xml" | grep "<release>" | sed -n 's:.*<release>\(.*\)</release>.*:\1:p')

    if grep -q $1:$ver $2; then
      echo $1:$ver "is already current"
    else
      echo "Updating $1 to $ver"
      sed -i '' "s/$1:[0-9\.]*/$1:$ver/" $2
    fi
  fi
}

# updates version for dependencies with static version numbers
# args
# 1 - name of the dependency as it would appear in gradle, like com.terraformersmc:modmenu
# 2 - target version string, like 2.0.14
# 3 - path to target .gradle file, relative to project root folder
#     should generally start with fabric/ forge/ or quilt/
updateStaticVersion() {
  if grep -q $1 $3; then
    if grep -q $1:$2 $3; then
      echo $1:$2 "is already current"
    else
      echo "Updating $1 to $2"
      sed -i '' "s/$1:[0-9\.\-\_a-zA-Z\+]*/$1:$2/" $3
    fi
  fi
}

updateVersion io.vram:bitkit fabric/project.gradle
updateVersion io.vram:bitraster fabric/project.gradle
updateVersion io.vram:special-circumstances fabric/project.gradle

updateVersion io.vram:frex-fabric-mc117 fabric/project.gradle
updateVersion io.vram:jmx-fabric-mc117 fabric/project.gradle
updateVersion io.vram:canvas-fabric-mc117 fabric/project.gradle

updateVersion grondag:exotic-art-core-mc117 fabric/project.gradle
updateVersion grondag:exotic-art-tech-mc117 fabric/project.gradle
updateVersion grondag:exotic-art-test-mc117 fabric/project.gradle
updateVersion grondag:exotic-art-unstable-mc117 fabric/project.gradle
updateVersion grondag:exotic-matter-mc117 fabric/project.gradle
updateVersion grondag:fermion-gui-mc117 fabric/project.gradle
updateVersion grondag:fermion-mc117 fabric/project.gradle
updateVersion grondag:fermion-modkeys-mc117 fabric/project.gradle
updateVersion grondag:fermion-orientation-mc117 fabric/project.gradle
updateVersion grondag:fermion-simulator-mc117 fabric/project.gradle
updateVersion grondag:fermion-varia-mc117 fabric/project.gradle
updateVersion grondag:fluidity-mc117 fabric/project.gradle
updateVersion grondag:fonthack-mc117 fabric/project.gradle
updateVersion grondag:mcmarkdown-mc117 fabric/project.gradle

# https://www.curseforge.com/minecraft/mc-mods/modmenu/files
updateStaticVersion com.terraformersmc:modmenu 2.0.14 fabric/project.gradle
# https://www.curseforge.com/minecraft/mc-mods/cloth-config/files
updateStaticVersion me.shedaniel.cloth:cloth-config-fabric 5.1.40 fabric/project.gradle
# https://www.curseforge.com/minecraft/mc-mods/roughly-enough-items/files
updateStaticVersion me.shedaniel:RoughlyEnoughItems-fabric 6.2.335 fabric/project.gradle

sed -i '' 's/"fabricloader": ".*"/"fabricloader": ">=0.12.5"/' fabric/src/main/resources/fabric.mod.json
sed -i '' 's/"minecraft": ".*"/"minecraft": "1.17.1"/' fabric/src/main/resources/fabric.mod.json


if [[ $1 == 'auto' ]]; then
    if output=$(git status --porcelain) && [ -z "$output" ]; then
      echo "Auto-update actions not required - no changes."
    else
      echo "Attempting test build"
      cd fabric

      if ./gradlew build; then
        echo "Gradle build successful, commiting changes to git"
        # should not be needed?
        #git add *
        git commit -m "Gruntle automatic update"
        git push

        echo "Publishing to maven"
        cd fabric
        ./gradlew publish --rerun-tasks
        cd ..
      else
        echo "Gradle build failed. Cannot continue."
      fi

      cd ..
    fi
fi
