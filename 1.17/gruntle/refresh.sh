readonly MC_TAG="mc117"
# https://www.curseforge.com/minecraft/mc-mods/modmenu/files
readonly MOD_MENU_VERSION="2.0.14"
# https://www.curseforge.com/minecraft/mc-mods/cloth-config/files
readonly CLOTH_CONFIG_VERSION="5.1.40"
# https://www.curseforge.com/minecraft/mc-mods/roughly-enough-items/files
readonly REI_VERSION="6.2.335"

# https://fabricmc.net/versions.html
readonly LOADER_VERSION="0.12.8"
readonly MC_FULL_VERSION="1.17.1"

### START COMMON CODE ##########################################

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
updateStaticVersion()
{
  if grep -q $1 $3; then
    if grep -q $1:$2 $3; then
      echo $1:$2 "is already current"
    else
      echo "Updating $1 to $2"
      sed -i '' "s/$1:[0-9\.\-\_a-zA-Z\+]*/$1:$2/" $3
    fi
  fi
}

publishFabric()
{
  cd fabric
  ./gradlew build publish githubRelease
  cd ..
}

updateVersion io.vram:bitkit fabric/project.gradle
updateVersion io.vram:bitraster fabric/project.gradle
updateVersion io.vram:special-circumstances fabric/project.gradle

updateVersion "io.vram:frex-fabric-$MC_TAG" fabric/project.gradle
updateVersion "io.vram:jmx-fabric-$MC_TAG" fabric/project.gradle
updateVersion "io.vram:canvas-fabric-$MC_TAG" fabric/project.gradle

updateVersion "grondag:exotic-art-core-$MC_TAG" fabric/project.gradle
updateVersion "grondag:exotic-art-tech-$MC_TAG" fabric/project.gradle
updateVersion "grondag:exotic-art-test-$MC_TAG" fabric/project.gradle
updateVersion "grondag:exotic-art-unstable-$MC_TAG" fabric/project.gradle
updateVersion "grondag:exotic-matter-$MC_TAG" fabric/project.gradle
updateVersion "grondag:fermion-gui-$MC_TAG" fabric/project.gradle
updateVersion "grondag:fermion-$MC_TAG" fabric/project.gradle
updateVersion "grondag:fermion-modkeys-$MC_TAG" fabric/project.gradle
updateVersion "grondag:fermion-orientation-$MC_TAG" fabric/project.gradle
updateVersion "grondag:fermion-simulator-$MC_TAG" fabric/project.gradle
updateVersion "grondag:fermion-varia-$MC_TAG" fabric/project.gradle
updateVersion "grondag:fluidity-$MC_TAG" fabric/project.gradle
updateVersion "grondag:fonthack-$MC_TAG" fabric/project.gradle
updateVersion "grondag:mcmarkdown-$MC_TAG" fabric/project.gradle

updateStaticVersion com.terraformersmc:modmenu $MOD_MENU_VERSION fabric/project.gradle
updateStaticVersion me.shedaniel.cloth:cloth-config-fabric $CLOTH_CONFIG_VERSION fabric/project.gradle
updateStaticVersion me.shedaniel:RoughlyEnoughItems-fabric $REI_VERSION fabric/project.gradle

sed -i '' "s/\"fabricloader\": \".*\"/\"fabricloader\": \">=$LOADER_VERSION\"/" fabric/src/main/resources/fabric.mod.json
sed -i '' "s/\"minecraft\": \".*\"/\"minecraft\": \"$MC_FULL_VERSION\"/" fabric/src/main/resources/fabric.mod.json

if [[ $1 == 'auto' ]]; then
    if output=$(git status --porcelain) && [ -z "$output" ]; then
      # We haven't changed anything but check if latest commit is published
      mod_name=$(grep "mod_name=" "fabric/gradle.properties" | sed -n 's:.*mod_name=\(.*\):\1:p')
      maven_group=$(grep "group=" "fabric/gradle.properties" | sed -n 's:.*group=\(.*\):\1:p')
      subUrl=${maven_group//[:\.]/\/}
      major_minor=$(grep "mod_version=" "fabric/gradle.properties" | sed -n 's:.*mod_version=\(.*\):\1:p')
      patch=$(git rev-list --count HEAD)
      mavenVer=$(curl -s "https://maven.vram.io/$subUrl/$mod_name-fabric-$MC_TAG/maven-metadata.xml" | grep "<release>" | sed -n 's:.*<release>\(.*\)</release>.*:\1:p')

      if [[ "$mavenVer" == "$major_minor.$patch" ]]; then
        echo "No Gruntle update actions required - no dependency changes and latest publish version $major_minor.$patch is current with the commit log count."
      else
        echo "Publishing jar because maven release $mavenVer is not current with expected version $major_minor.$patch."
        publishFabric
      fi
    else
      echo "Gruntle made changes. Attempting automatic check-in."
      echo "Attempting test build"
      cd fabric

      if ./gradlew build; then
        cd ..
        echo "Gradle build successful, commiting changes to git"
        git add *
        git commit -m "Gruntle automatic update"
        git push

        echo "Publishing"
        publishFabric
      else
        cd ..
        echo "Gradle build failed. Cannot continue."
      fi
    fi
fi
