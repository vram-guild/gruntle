# https://modrinth.com/mod/modmenu/versions
readonly MOD_MENU_VERSION="4.1.1"
# https://www.curseforge.com/minecraft/mc-mods/cloth-config/files
readonly CLOTH_CONFIG_VERSION="8.2.88"
# https://www.curseforge.com/minecraft/mc-mods/cloth-config-forge/files
readonly CLOTH_CONFIG_FORGE_VERSION="8.2.88"
# https://www.curseforge.com/minecraft/mc-mods/roughly-enough-items/files
readonly REI_VERSION="9.1.595"
readonly REI_FORGE_VERSION="9.1.595"
# https://www.curseforge.com/minecraft/mc-mods/architectury-api/files
# https://modrinth.com/mod/architectury-api/versions
readonly ARCH_VERSION="6.5.82"
readonly ARCH_FORGE_VERSION="6.5.82"
# https://maven.gegy.dev/releases/dev/lambdaurora/spruceui
readonly SPRUCE_UI_VERSION="4.1.0+1.19.2"

# https://fabricmc.net/versions.html
readonly LOADER_VERSION="0.14.19"
# Used as base version number for all mods specific to MC version
# Last digit will be git commit number
readonly MOD_VERSION="19.2"
readonly MC_FULL_VERSION="1.19.2"
# Following is used in fabric.mod.json because pre-release suffixes are apparently parsed differently there
readonly MC_SHORT_VERSION="1.19.2"

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
    ver=$(curl -s "https://maven.vram.io/$subUrl/maven-metadata.xml" | grep "<version>$MOD_VERSION" | tail -1 |sed -n 's:.*<version>\(.*\)</version>.*:\1:p')

    if grep -q $1:$ver $2; then
      echo $1:$ver "is already current"
    else
      echo "Updating $1 to $ver"
      sed -i "s/$1:[0-9\.]*/$1:$ver/" $2
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
      sed -i "s/$1:[0-9\.\-\_a-zA-Z\+]*/$1:$2/" $3
    fi
  fi
}

publishFabric()
{
  cd fabric
  ../gradlew build publish github --rerun-tasks
  cd ..
}

publishForge()
{
  cd forge
  ../gradlew build publish github --rerun-tasks
  cd ..
}

if ! grep -q project_common.gradle @track_minecraft_version; then
  echo "Project is configured to mirror Minecraft versions."
  echo "Artifact versions will begin with $MOD_VERSION."
  sed -i "s/^ext\.mod_version.*/ext\.mod_version = '$MOD_VERSION'/" 'project_common.gradle'
fi

updateVersion io.vram:bitkit fabric/project.gradle
updateVersion io.vram:bitkit forge/project.gradle

updateVersion io.vram:bitraster fabric/project.gradle
updateVersion io.vram:bitraster forge/project.gradle

updateVersion io.vram:special-circumstances fabric/project.gradle
updateVersion io.vram:special-circumstances forge/project.gradle

updateVersion io.vram:dtklib fabric/project.gradle
updateVersion io.vram:dtklib forge/project.gradle

updateVersion "io.vram:frex-fabric" fabric/project.gradle
updateVersion "io.vram:frex-forge" forge/project.gradle

updateVersion "io.vram:jmx-fabric" fabric/project.gradle
updateVersion "io.vram:jmx-forge" forge/project.gradle

updateVersion "io.vram:canvas-fabric" fabric/project.gradle
updateVersion "io.vram:canvas-forge" forge/project.gradle

updateVersion "io.vram:littlegui-fabric" fabric/project.gradle
updateVersion "io.vram:littlegui-forge" forge/project.gradle

updateVersion "io.vram:modkeys-fabric" fabric/project.gradle
updateVersion "io.vram:modkeys-forge" forge/project.gradle

updateVersion "grondag:exotic-matter-fabric" fabric/project.gradle
updateVersion "grondag:exotic-matter-forge" forge/project.gradle

updateVersion "io.vram:fluidity-fabric" fabric/project.gradle
updateVersion "io.vram:fluidity-forge" forge/project.gradle

updateVersion "grondag:fermion-gui" fabric/project.gradle
updateVersion "grondag:fermion" fabric/project.gradle
updateVersion "grondag:fermion-modkeys" fabric/project.gradle
updateVersion "grondag:fermion-orientation" fabric/project.gradle
updateVersion "grondag:fermion-simulator" fabric/project.gradle
updateVersion "grondag:fermion-varia" fabric/project.gradle

updateStaticVersion com.terraformersmc:modmenu $MOD_MENU_VERSION fabric/project.gradle
updateStaticVersion me.shedaniel.cloth:cloth-config-fabric $CLOTH_CONFIG_VERSION fabric/project.gradle
updateStaticVersion me.shedaniel.cloth:cloth-config-forge $CLOTH_CONFIG_FORGE_VERSION forge/project.gradle
updateStaticVersion me.shedaniel:RoughlyEnoughItems-fabric $REI_VERSION fabric/project.gradle
updateStaticVersion me.shedaniel:RoughlyEnoughItems-forge $REI_FORGE_VERSION forge/project.gradle
updateStaticVersion dev.architectury:architectury-fabric $ARCH_VERSION fabric/project.gradle
updateStaticVersion dev.architectury:architectury-fabric $ARCH_FORGE_VERSION forge/project.gradle
updateStaticVersion dev.lambdaurora:spruceui $SPRUCE_UI_VERSION fabric/project.gradle

sed -i "s/\"fabricloader\": \".*\"/\"fabricloader\": \">=$LOADER_VERSION\"/" fabric/src/main/resources/fabric.mod.json
sed -i "s/\"minecraft\": \".*\"/\"minecraft\": \">=$MC_SHORT_VERSION\"/" fabric/src/main/resources/fabric.mod.json
sed -i "s/\"architectury\": \".*\"/\"architectury\": \">=$ARCH_VERSION\"/" fabric/src/main/resources/fabric.mod.json

if [[ $1 == 'auto' ]]; then
  build_forge=$(sed -n 's/^ext\.build_forge *= *//p' 'project_common.gradle')
  echo "Build Forge $build_forge"

  if output=$(git status --porcelain) && [ -z "$output" ]; then
    # We haven't changed anything but check if latest commit is published
    mod_name=$(sed -n "s/^ext\.mod_name *= *'\([0-9a-zA-Z]*\)'/\1/p" 'project_common.gradle')
    maven_group=$(sed -n "s/^project\.group *= *'\([\.0-9a-zA-Z]*\)'/\1/p" 'project_common.gradle')
    subUrl=${maven_group//[:\.]/\/}
    major_minor=$(sed -n "s/^ext\.mod_version *= *'\([/.0-9a-zA-Z]*\)'/\1/p" 'project_common.gradle')
    patch=$(git rev-list --count HEAD)

    fabricMavenVer=$(curl -s "https://maven.vram.io/$subUrl/$mod_name-fabric/maven-metadata.xml" | grep "<version>$MOD_VERSION" | tail -1 | sed -n 's:.*<version>\(.*\)</version>.*:\1:p')
    echo "Current Fabric Maven Version $fabricMavenVer"
    forgeMavenVer=$(curl -s "https://maven.vram.io/$subUrl/$mod_name-forge/maven-metadata.xml" | grep "<version>$MOD_VERSION" | tail -1 | sed -n 's:.*<version>\(.*\)</version>.*:\1:p')
    echo "Current Forge Maven Version $forgeMavenVer"
    echo "Expected Maven version $major_minor.$patch"

    if [[ "$fabricMavenVer" == "$major_minor.$patch" ]] && ( [[ "$forgeMavenVer" == "$major_minor.$patch" ]] || [[ ! "$build_forge" == "true" ]] ); then
      echo "No Gruntle update actions required - no dependency changes and latest publish version $major_minor.$patch is current with the commit log count."
    else
      if [[ ! "$fabricMavenVer" == "$major_minor.$patch" ]]; then
        echo "Publishing Fabric jar because maven release $mavenVer is not current with expected version $major_minor.$patch."
        publishFabric
      fi

      if [[ ! "$forgeMavenVer" == "$major_minor.$patch" ]] && [[ "$build_forge" == "true" ]]; then
        echo "Publishing Forge jar because maven release $mavenVer is not current with expected version $major_minor.$patch."
        publishForge
      fi
    fi
  else
    echo "Gruntle made changes. Attempting automatic check-in."
    echo "Attempting Fabric test build"
    cd fabric

    if ../gradlew build; then
      echo "Attempting Forge test build"
      cd ../forge

      if [[ ! "$build_forge" == "true" ]] || ../gradlew build; then
        cd ..
        echo "Gradle builds successful, commiting changes to git"
        git add *
        git commit -m "Gruntle automatic update"
        git push

        echo "Publishing"
        publishFabric

        if [[ "$build_forge" == "true" ]]; then
          publishForge
        fi
      else
        cd ..
        echo "Forge build failed. Cannot continue."
      fi
    else
      cd ..
      echo "Fabric build failed. Cannot continue."
    fi
  fi
fi
