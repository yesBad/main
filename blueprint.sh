#!/bin/bash

# blueprint.zip
# github.com/teamblueprint/main
# prpl.wtf

# This should allow Blueprint to run in Docker. Please note that changing the $FOLDER variable after running
# the Blueprint installation script will not change anything in any files besides blueprint.sh.
  FOLDER="/var/www/pterodactyl" #;

# If the version below does not match your downloaded version, please let us know.
  VERSION="alpha-SLX"



# Allow non-default Pterodactyl installation folders.
if [[ $_FOLDER != "" ]]; then
  if [[ ( ! -f "$FOLDER/.blueprint/extensions/blueprint/private/db/version" ) && ( $FOLDER == "/var/www/pterodactyl" ) ]]; then
    sed -i -E "s|FOLDER=\"/var/www/pterodactyl\" #;|FOLDER=\"$_FOLDER\" #;|g" "$_FOLDER"/blueprint.sh
  else
    echo "Variable cannot be replaced right now."
    exit 2
  fi
fi

# Check for panels that are using Docker, which should have better support in the future.
if [[ -f "/.dockerenv" ]]; then
  DOCKER="y"
else
  DOCKER="n"
fi

if [[ -d "$FOLDER/blueprint" ]]; then mv $FOLDER/blueprint $FOLDER/.blueprint; fi

if [[ $VERSION != "" ]]; then
  # This function makes sure some placeholders get replaced with the current Blueprint version.
  if [[ ! -f "$FOLDER/.blueprint/extensions/blueprint/private/db/version" ]]; then
    sed -E -i "s*::v*$VERSION*g" $FOLDER/app/BlueprintFramework/Services/PlaceholderService/BlueprintPlaceholderService.php
    sed -E -i "s*::v*$VERSION*g" $FOLDER/.blueprint/extensions/blueprint/public/index.html
    touch $FOLDER/.blueprint/extensions/blueprint/private/db/version
  fi
fi

# Write environment variables.
export BLUEPRINT__FOLDER=$FOLDER
export BLUEPRINT__VERSION=$VERSION
export BLUEPRINT__DEBUG="$FOLDER"/.blueprint/extensions/blueprint/private/debug/logs.txt
export NODE_OPTIONS=--openssl-legacy-provider

# Automatically navigate to the Pterodactyl directory when running the core.
cd $FOLDER || return

# Import libraries.
source .blueprint/lib/parse_yaml.sh || missinglibs+="[parse_yaml]"
source .blueprint/lib/grabenv.sh    || missinglibs+="[grabenv]"
source .blueprint/lib/logFormat.sh  || missinglibs+="[logFormat]"
source .blueprint/lib/misc.sh       || missinglibs+="[misc]"


# -config
# usage: "cITEM=VALUE bash blueprint.sh -config"
if [[ "$1" == "-config" ]]; then

  # cTELEMETRY_ID
  # Update the telemetry id.
  if [[ "$cTELEMETRY_ID" != "" ]]; then
    echo "$cTELEMETRY_ID" > .blueprint/extensions/blueprint/private/db/telemetry_id
  fi

  # cDEVELOPER
  # Enable/Disable developer mode.
  if [[ "$cDEVELOPER" != "" ]]; then
    if [[ "$cDEVELOPER" == "true" ]]; then 
      dbAdd "blueprint.developerEnabled"
    else 
      dbRemove "blueprint.developerEnabled"
    fi
  fi

  echo .
  exit 0
fi

cdhalt() { PRINT FATAL "Attempted navigation into nonexistent directory, halting process."; exit 1; }


depend() {
  # Check for incorrect node version.
  nodeVer=$(node -v)
  if [[ $nodeVer != "v17."* ]] \
  && [[ $nodeVer != "v18."* ]] \
  && [[ $nodeVer != "v19."* ]] \
  && [[ $nodeVer != "v20."* ]] \
  && [[ $nodeVer != "v21."* ]]; then 
    DEPEND_MISSING=true
  fi

  # Check for required (both internal and external) dependencies.
  if \
  ! [ -x "$(command -v unzip)" ] ||                          # unzip
  ! [ -x "$(command -v node)" ] ||                           # node
  ! [ -x "$(command -v yarn)" ] ||                           # yarn
  ! [ -x "$(command -v zip)" ] ||                            # zip
  ! [ -x "$(command -v curl)" ] ||                           # curl
  ! [ -x "$(command -v php)" ] ||                            # php
  ! [ -x "$(command -v git)" ] ||                            # git
  ! [ -x "$(command -v grep)" ] ||                           # grep
  ! [ -x "$(command -v sed)" ] ||                            # sed
  ! [ -x "$(command -v awk)" ] ||                            # awk
  ! [ "$(ls "node_modules/"*"cross-env"* 2> /dev/null)" ] || # cross-env
  ! [ "$(ls "node_modules/"*"webpack"* 2> /dev/null)"   ] || # webpack
  ! [ "$(ls "node_modules/"*"react"* 2> /dev/null)"     ] || # react
  [[ $missinglibs != "" ]]; then                             # internal
    DEPEND_MISSING=true
  fi

  # Exit when missing dependencies.
  if [[ $DEPEND_MISSING == true ]]; then 
    PRINT FATAL "Some framework dependencies are not installed or detected."

    if [[ $nodeVer != "v18."* ]] \
    && [[ $nodeVer != "v19."* ]] \
    && [[ $nodeVer != "v20."* ]] \
    && [[ $nodeVer != "v21."* ]]; then 
      PRINT FATAL "Required dependency \"node\" is using an unsupported version."
    fi

    if ! [ -x "$(command -v unzip)"                          ]; then PRINT FATAL "Required dependency \"unzip\" is not installed or detected.";     fi
    if ! [ -x "$(command -v node)"                           ]; then PRINT FATAL "Required dependency \"node\" is not installed or detected.";      fi
    if ! [ -x "$(command -v yarn)"                           ]; then PRINT FATAL "Required dependency \"yarn\" is not installed or detected.";      fi
    if ! [ -x "$(command -v zip)"                            ]; then PRINT FATAL "Required dependency \"zip\" is not installed or detected.";       fi
    if ! [ -x "$(command -v curl)"                           ]; then PRINT FATAL "Required dependency \"curl\" is not installed or detected.";      fi
    if ! [ -x "$(command -v php)"                            ]; then PRINT FATAL "Required dependency \"php\" is not installed or detected.";       fi
    if ! [ -x "$(command -v git)"                            ]; then PRINT FATAL "Required dependency \"git\" is not installed or detected.";       fi
    if ! [ -x "$(command -v grep)"                           ]; then PRINT FATAL "Required dependency \"grep\" is not installed or detected.";      fi
    if ! [ -x "$(command -v sed)"                            ]; then PRINT FATAL "Required dependency \"sed\" is not installed or detected.";       fi
    if ! [ -x "$(command -v awk)"                            ]; then PRINT FATAL "Required dependency \"awk\" is not installed or detected.";       fi
    if ! [ "$(ls "node_modules/"*"cross-env"* 2> /dev/null)" ]; then PRINT FATAL "Required dependency \"cross-env\" is not installed or detected."; fi
    if ! [ "$(ls "node_modules/"*"webpack"* 2> /dev/null)"   ]; then PRINT FATAL "Required dependency \"webpack\" is not installed or detected.";   fi
    if ! [ "$(ls "node_modules/"*"react"* 2> /dev/null)"     ]; then PRINT FATAL "Required dependency \"react\" is not installed or detected.";     fi

    if [[ $missinglibs == *"[parse_yaml]"*               ]]; then PRINT FATAL "Required internal dependency \"internal:parse_yaml\" is not installed or detected.";               fi
    if [[ $missinglibs == *"[grabEnv]"*                  ]]; then PRINT FATAL "Required internal dependency \"internal:grabEnv\" is not installed or detected.";                  fi
    if [[ $missinglibs == *"[logFormat]"*                ]]; then PRINT FATAL "Required internal dependency \"internal:logFormat\" is not installed or detected.";                fi
    if [[ $missinglibs == *"[misc]"*                     ]]; then PRINT FATAL "Required internal dependency \"internal:misc\" is not installed or detected.";                     fi

    exit 1
  fi
}

# Assign variables for extension flags.
assignflags() {
  F_ignorePlaceholders=false
  F_ignoreAlphabetPlaceholders=false
  F_hasInstallScript=false
  F_hasRemovalScript=false
  F_hasExportScript=false
  F_developerIgnoreInstallScript=false
  F_developerIgnoreRebuild=false
  if [[ ( $flags == *"ignorePlaceholders,"*           ) || ( $flags == *"ignorePlaceholders"           ) ]]; then F_ignorePlaceholders=true           ;fi
  if [[ ( $flags == *"ignoreAlphabetPlaceholders,"*   ) || ( $flags == *"ignoreAlphabetPlaceholders"   ) ]]; then F_ignoreAlphabetPlaceholders=true   ;fi
  if [[ ( $flags == *"hasInstallScript,"*             ) || ( $flags == *"hasInstallScript"             ) ]]; then F_hasInstallScript=true             ;fi
  if [[ ( $flags == *"hasRemovalScript,"*             ) || ( $flags == *"hasRemovalScript"             ) ]]; then F_hasRemovalScript=true             ;fi
  if [[ ( $flags == *"hasExportScript,"*              ) || ( $flags == *"hasExportScript"              ) ]]; then F_hasExportScript=true              ;fi
  if [[ ( $flags == *"developerIgnoreInstallScript,"* ) || ( $flags == *"developerIgnoreInstallScript" ) ]]; then F_developerIgnoreInstallScript=true ;fi
  if [[ ( $flags == *"developerIgnoreRebuild,"*       ) || ( $flags == *"developerIgnoreRebuild"       ) ]]; then F_developerIgnoreRebuild=true       ;fi
}


# Adds the "blueprint" command to the /usr/local/bin directory and configures the correct permissions for it.
{
  touch /usr/local/bin/blueprint
  chmod u+x \
    $FOLDER/blueprint.sh \
    /usr/local/bin/blueprint
} >> $BLUEPRINT__DEBUG
echo -e "#!/bin/bash\nbash $FOLDER/blueprint.sh -bash \$@;" > /usr/local/bin/blueprint


if [[ $1 != "-bash" ]]; then
  if dbValidate "blueprint.setupFinished"; then
    PRINT FATAL "Installation process has already been finished before, consider using the 'blueprint' command."
    exit 2
  else
    # Only run if Blueprint is not in the process of upgrading.
    if [[ $1 != "--post-upgrade" ]]; then
      echo -e "  ██\n██  ██\n  ████\n"; # Blueprint "ascii" "logo".
      if [[ $DOCKER == "y" ]]; then
        PRINT WARNING "Docker is untested and you might run into issues."
      fi
    fi

    PRINT INFO "Searching and validating framework dependencies.."
    # Check if required programs are installed
    depend

    # Link directories.
    PRINT INFO "Linking directories and filesystems.."
    cd $FOLDER/public/extensions        || cdhalt; ln -s -T $FOLDER/.blueprint/extensions/blueprint/public blueprint  2>> $BLUEPRINT__DEBUG; cd $FOLDER || cdhalt
    cd $FOLDER/public/assets/extensions || cdhalt; ln -s -T $FOLDER/.blueprint/extensions/blueprint/assets blueprint  2>> $BLUEPRINT__DEBUG; cd $FOLDER || cdhalt
    php artisan storage:link &>> $BLUEPRINT__DEBUG 

    PRINT INFO "Replacing internal placeholders.."
    # Update folder placeholder on PlaceholderService and admin layout.
    sed -i "s!::f!$FOLDER!g" $FOLDER/app/BlueprintFramework/Services/PlaceholderService/BlueprintPlaceholderService.php
    sed -i "s!::f!$FOLDER!g" $FOLDER/resources/views/layouts/admin.blade.php
    # Copy "Blueprint" extension page logo from assets.
    cp $FOLDER/.blueprint/assets/logo.jpg $FOLDER/.blueprint/extensions/blueprint/assets/logo.jpg

    # Put application into maintenance.
    PRINT INFO "Put application into maintenance mode."
    php artisan down &>> $BLUEPRINT__DEBUG

    # Flush cache.
    PRINT INFO "Flushing view, config and route cache.."
    {
      php artisan view:clear
      php artisan config:clear
      php artisan route:cache
      php artisan cache:clear
    } &>> $BLUEPRINT__DEBUG 
    updateCacheReminder

    # Run migrations if Blueprint is not upgrading.
    if [[ $1 != "--post-upgrade" ]]; then
      PRINT INPUT "Would you like to migrate your database? (Y/n)"
      read -r YN
      if [[ ( $YN == "y"* ) || ( $YN == "Y"* ) || ( $YN == "" ) ]]; then 
        PRINT INFO "Running database migrations.."
        php artisan migrate --force
      else
        PRINT INFO "Database migrations have been skipped."
      fi
    fi

    # Make sure all files have correct permissions.
    PRINT INFO "Changing Pterodactyl file ownership to 'www-data'.."
    chown -R www-data:www-data \
      $FOLDER/.blueprint/* \
      $FOLDER/app/* \
      $FOLDER/config/* \
      $FOLDER/database/* \
      $FOLDER/public/* \
      $FOLDER/resources/* \
      $FOLDER/routes/* \
      $FOLDER/storage/*

    # Rebuild panel assets.
    PRINT INFO "Rebuilding panel assets.."
    yarn run build:production

    # Put application into production.
    PRINT INFO "Put application into production."
    php artisan up &>> $BLUEPRINT__DEBUG

    # Sync some database values.
    PRINT INFO "Syncing Blueprint-related database values.."
    php artisan bp:sync

    # Finish installation
    if [[ $1 != "--post-upgrade" ]]; then
      PRINT SUCCESS "Blueprint has completed it's installation process."
    fi

    dbAdd "blueprint.setupFinished"
    # Let the panel know the user has finished installation.
    sed -i "s!NOTINSTALLED!INSTALLED!g" $FOLDER/app/BlueprintFramework/Services/PlaceholderService/BlueprintPlaceholderService.php
    exit 1
  fi
fi


# help, -help, --help,
# h,    -h,    --h
if [[ ( $2 == "help" ) || ( $2 == "-help" ) || ( $2 == "--help" ) || 
      ( $2 == "h" )    || ( $2 == "-h" )    || ( $2 == "--h" )    || ( $2 == "" ) ]]; then VCMD="y"

  if dbValidate "blueprint.developerEnabled"; then
    help_dev_status=""
    help_dev_primary="\e[34;1m"
    help_dev_secondary="\e[34m"
  else 
    help_dev_status=" (disabled)"
    help_dev_primary="\x1b[2;1m"
    help_dev_secondary="\x1b[2m"
  fi

  echo -e "
\x1b[34;1mExtensions\x1b[0m\x1b[34m
  -install [name]      -i  install/update a blueprint extension
  -remove [name]       -r  remove a blueprint extension
  \x1b[0m
  
${help_dev_primary}Developer${help_dev_status}\x1b[0m${help_dev_secondary}
  -init                -I  initialize development files
  -build               -b  install/update your development files
  -export (expose)     -e  export/download your development files
  -wipe                -w  remove your development files
  \x1b[0m
  
\x1b[34;1mMisc\x1b[0m\x1b[34m
  -version             -v  returns the blueprint version
  -help                -h  displays this menu
  -info                -f  show neofetch-like information about blueprint
  -debug [lines]           print given amount of debug lines
  \x1b[0m
  
\x1b[34;1mAdvanced\x1b[0m\x1b[34m
  -upgrade (dev)           update/reset to a newer/development version
  -rerun-install           rerun the blueprint installation script
  \x1b[0m
  "
fi


# -i, -install
if [[ ( $2 == "-i" ) || ( $2 == "-install" ) ]]; then VCMD="y"
  if [[ $(( $# - 2 )) != 1 ]]; then PRINT FATAL "Expected 1 argument but got $(( $# - 2 )).";exit 2;fi
  if [[ ( $3 == "./"* ) || ( $3 == "../"* ) || ( $3 == "/"* ) ]]; then PRINT FATAL "Cannot import extensions from external paths.";exit 2;fi

  PRINT INFO "Searching and validating framework dependencies.."
  # Check if required programs are installed
  depend

  # The following code does some magic to allow for extensions with a
  # different root folder structure than expected by Blueprint.
  if [[ $3 == "[developer-build]" ]]; then
    dev=true
    n="dev"
    mkdir -p ".blueprint/tmp/dev"
    cp -R ".blueprint/dev/"* ".blueprint/tmp/dev/"
  else
    dev=false
    n="$3"
    FILE="${n}.blueprint"
    if [[ ( $FILE == *".blueprint.blueprint" ) && ( $n == *".blueprint" ) ]]; then PRINT FATAL "Argument one in '-install' must not end with '.blueprint'.";exit 2; fi
    if [[ ! -f "$FILE" ]]; then PRINT FATAL "$FILE could not be found or detected.";exit 2;fi

    ZIP="${n}.zip"
    cp "$FILE" ".blueprint/tmp/$ZIP"
    cd ".blueprint/tmp" || cdhalt
    unzip -o -qq "$ZIP"
    rm "$ZIP"
    if [[ ! -f "$n/*" ]]; then
      cd ".." || cdhalt
      rm -R "tmp"
      mkdir -p "tmp"
      cd "tmp" || cdhalt

      mkdir -p "./$n"
      cp "../../$FILE" "./$n/$ZIP"
      cd "$n" || cdhalt
      unzip -o -qq "$ZIP"
      rm "$ZIP"
      cd ".." || cdhalt
    fi
  fi

  # Return to the Pterodactyl installation folder.
  cd $FOLDER || cdhalt

  # Get all strings from the conf.yml file and make them accessible as variables.
  if [[ ! -f ".blueprint/tmp/$n/conf.yml" ]]; then 
    # Quit if the extension doesn't have a conf.yml file.
    rm -R ".blueprint/tmp/$n"
    PRINT FATAL "Extension configuration file not found or detected."
    exit 1
  fi

  eval "$(parse_yaml .blueprint/tmp/"${n}"/conf.yml conf_)"

  # Add aliases for config values to make working with them easier.
  name="$conf_info_name"
  identifier="$conf_info_identifier"
  description="$conf_info_description"
  flags="$conf_info_flags" #(optional)
  version="$conf_info_version"
  target="$conf_info_target"
  author="$conf_info_author" #(optional)
  icon="$conf_info_icon" #(optional)
  website="$conf_info_website"; #(optional)

  admin_view="$conf_admin_view"
  admin_controller="$conf_admin_controller"; #(optional)
  admin_css="$conf_admin_css"; #(optional)
  admin_wrapper="$conf_admin_wrapper"; #(optional)

  dashboard_css="$conf_dashboard_css"; #(optional)
  dashboard_wrapper="$conf_dashboard_wrapper"; #(optional)
  dashboard_components="$conf_dashboard_components"; #(optional)

  data_directory="$conf_data_directory"; #(optional)
  data_public="$conf_data_public"; #(optional)

  database_migrations="$conf_database_migrations"; #(optional)
  
  # "prevent" folder "escaping"
  if [[ ( $icon                 == "/"* ) || ( $icon                 == *"/.."* ) || ( $icon                 == *"../"* ) || ( $icon                 == *"/../"* ) || ( $icon                 == *"\n"* ) ]] \
  || [[ ( $admin_view           == "/"* ) || ( $admin_view           == *"/.."* ) || ( $admin_view           == *"../"* ) || ( $admin_view           == *"/../"* ) || ( $admin_view           == *"\n"* ) ]] \
  || [[ ( $admin_controller     == "/"* ) || ( $admin_controller     == *"/.."* ) || ( $admin_controller     == *"../"* ) || ( $admin_controller     == *"/../"* ) || ( $admin_controller     == *"\n"* ) ]] \
  || [[ ( $admin_css            == "/"* ) || ( $admin_css            == *"/.."* ) || ( $admin_css            == *"../"* ) || ( $admin_css            == *"/../"* ) || ( $admin_css            == *"\n"* ) ]] \
  || [[ ( $admin_wrapper        == "/"* ) || ( $admin_wrapper        == *"/.."* ) || ( $admin_wrapper        == *"../"* ) || ( $admin_wrapper        == *"/../"* ) || ( $admin_wrapper        == *"\n"* ) ]] \
  || [[ ( $dashboard_css        == "/"* ) || ( $dashboard_css        == *"/.."* ) || ( $dashboard_css        == *"../"* ) || ( $dashboard_css        == *"/../"* ) || ( $dashboard_css        == *"\n"* ) ]] \
  || [[ ( $dashboard_wrapper    == "/"* ) || ( $dashboard_wrapper    == *"/.."* ) || ( $dashboard_wrapper    == *"../"* ) || ( $dashboard_wrapper    == *"/../"* ) || ( $dashboard_wrapper    == *"\n"* ) ]] \
  || [[ ( $dashboard_components == "/"* ) || ( $dashboard_components == *"/.."* ) || ( $dashboard_components == *"../"* ) || ( $dashboard_components == *"/../"* ) || ( $dashboard_components == *"\n"* ) ]] \
  || [[ ( $data_directory       == "/"* ) || ( $data_directory       == *"/.."* ) || ( $data_directory       == *"../"* ) || ( $data_directory       == *"/../"* ) || ( $data_directory       == *"\n"* ) ]] \
  || [[ ( $data_public          == "/"* ) || ( $data_public          == *"/.."* ) || ( $data_public          == *"../"* ) || ( $data_public          == *"/../"* ) || ( $data_public          == *"\n"* ) ]] \
  || [[ ( $database_migrations  == "/"* ) || ( $database_migrations  == *"/.."* ) || ( $database_migrations  == *"../"* ) || ( $database_migrations  == *"/../"* ) || ( $database_migrations  == *"\n"* ) ]]; then
    rm -R ".blueprint/tmp/$n"
    PRINT FATAL "Config file paths cannot escape the extension bundle."
    exit 1
  fi

  # prevent potentional problems during installation due to wrongly defined folders
  if [[ ( $dashboard_components == *"/" ) || 
        ( $data_directory == *"/"       ) || 
        ( $data_public == *"/"          ) || 
        ( $database_migrations == *"/"  ) ]]; then
    rm -R ".blueprint/tmp/$n"
    PRINT FATAL "Directory paths in conf.yml should not end with a slash."
    exit 1
  fi

  # check if extension still has placeholder values
  if [[ ( $name    == "[name]" ) || ( $identifier == "[identifier]" ) || ( $description == "[description]" ) ]] \
  || [[ ( $version == "[ver]"  ) || ( $target     == "[version]"    ) || ( $author      == "[author]"      ) ]]; then
    rm -R ".blueprint/tmp/$n"
    PRINT FATAL "Extension contains placeholder values which need to be replaced."
    exit 1
  fi

  # Detect if extension is already installed and prepare the upgrading process.
  if [[ $(cat .blueprint/extensions/blueprint/private/db/installed_extensions) == *"$identifier,"* ]]; then
    PRINT INFO "Switching to update process as extension has already been installed."
    eval "$(parse_yaml .blueprint/extensions/"${identifier}"/private/.store/conf.yml old_)"
    DUPLICATE="y"

    if [[ ! -f ".blueprint/extensions/$identifier/private/.store/build/button.blade.php" ]]; then
      rm -R ".blueprint/tmp/$n"
      PRINT FATAL "Upgrading extension has failed due to missing essential .store files."
      exit 1
    fi

    # Clean up some old extension files.
    if [[ $old_data_public != "" ]]; then
      # Clean up old public folder.
      rm -R ".blueprint/extensions/$identifier/public"
      mkdir ".blueprint/extensions/$identifier/public"
    fi
  fi

  # Assign variables to extension flags.
  PRINT INFO "Reading and assigning extension flags.."
  assignflags

  # Force http/https url scheme for extension website urls.
  if [[ $website != "" ]]; then
    if [[ ( $website != "https://"* ) && ( $website != "http://"* ) ]]; then
      website="http://${conf_info_website}"
      conf_info_website="${website}"
    fi


    # Change link icon depending on website url.
    websiteiconclass="bx-link-external"

    # git
    if [[ $website == *"://github.com/"*        ]] || [[ $website == *"://www.github.com/"*        ]] ||
       [[ $website == *"://github.com"          ]] || [[ $website == *"://www.github.com"          ]] ||
       [[ $website == *"://gitlab.com/"*        ]] || [[ $website == *"://www.gitlab.com/"*        ]] ||
       [[ $website == *"://gitlab.com"          ]] || [[ $website == *"://www.gitlab.com"          ]]; then websiteiconclass="bx-git-branch";fi
    # marketplaces
    if [[ $website == *"://sourcexchange.net/"* ]] || [[ $website == *"://www.sourcexchange.net/"* ]] ||
       [[ $website == *"://sourcexchange.net"   ]] || [[ $website == *"://www.sourcexchange.net"   ]] ||
       [[ $website == *"://builtbybit.com/"*    ]] || [[ $website == *"://www.builtbybit.com/"*    ]] ||
       [[ $website == *"://builtbybit.com"      ]] || [[ $website == *"://www.builtbybit.com"      ]] ||
       [[ $website == *"://builtbyb.it/"*       ]] || [[ $website == *"://www.builtbyb.it/"*       ]] ||
       [[ $website == *"://builtbyb.it"         ]] || [[ $website == *"://www.builtbyb.it"         ]]; then websiteiconclass="bx-store";fi
    # discord
    if [[ $website == *"://discord.com/"*       ]] || [[ $website == *"://www.discord.com/"*       ]] ||
       [[ $website == *"://discord.com"         ]] || [[ $website == *"://www.discord.com"         ]] ||
       [[ $website == *"://discord.gg/"*        ]] || [[ $website == *"://www.discord.gg/"*        ]] ||
       [[ $website == *"://discord.gg"          ]] || [[ $website == *"://www.discord.gg"          ]]; then websiteiconclass="bxl-discord-alt";fi
    # patreon
    if [[ $website == *"://patreon.com/"*       ]] || [[ $website == *"://www.patreon.com/"*       ]] ||
       [[ $website == *"://patreon.com"         ]] || [[ $website == *"://www.patreon.com"         ]]; then websiteiconclass="bxl-patreon";fi
    # reddit
    if [[ $website == *"://reddit.com/"*        ]] || [[ $website == *"://www.reddit.com/"*        ]] ||
       [[ $website == *"://reddit.com"          ]] || [[ $website == *"://www.reddit.com"          ]]; then websiteiconclass="bxl-reddit";fi
    # trello
    if [[ $website == *"://trello.com/"*        ]] || [[ $website == *"://www.trello.com/"*        ]] ||
       [[ $website == *"://trello.com"          ]] || [[ $website == *"://www.trello.com"          ]]; then websiteiconclass="bxl-trello";fi
  fi

  if [[ $dev == true ]]; then
    mv ".blueprint/tmp/$n" ".blueprint/tmp/$identifier"
    n=$identifier
  fi

  if ! $F_ignorePlaceholders; then
    # Prepare variables for placeholders
    PRINT INFO "Writing extension placeholders.."
    DIR=".blueprint/tmp/$n"
    INSTALLMODE="normal"
    installation_timestamp=$(date +%s)
    if [[ $dev == true ]]; then INSTALLMODE="developer"; fi
    EXTPUBDIR="$FOLDER/.blueprint/extensions/$identifier/public"
    if [[ $data_public == "" ]]; then EXTPUBDIR="null"; fi

    PLACE_PLACEHOLDERS() {
      local dir="$1"
      for file in "$dir"/*; do
        if [ -f "$file" ]; then
          file=${file// /\\ }
          sed -i \
            -e "s~\^#version#\^~$version~g" \
            -e "s~\^#author#\^~$author~g" \
            -e "s~\^#name#\^~$name~g" \
            -e "s~\^#identifier#\^~$identifier~g" \
            -e "s~\^#path#\^~$FOLDER~g" \
            -e "s~\^#datapath#\^~$FOLDER/.blueprint/extensions/$identifier/private~g" \
            -e "s~\^#publicpath#\^~$EXTPUBDIR~g" \
            -e "s~\^#installmode#\^~$INSTALLMODE~g" \
            -e "s~\^#blueprintversion#\^~$VERSION~g" \
            -e "s~\^#timestamp#\^~$installation_timestamp~g" \
            -e "s~\^#componentroot#\^~@/blueprint/extensions/$identifier~g" \
            "$file"
          if ! $F_ignoreAlphabetPlaceholders; then
            sed -i \
              -e "s~__version__~$version~g" \
              -e "s~__author__~$author~g" \
              -e "s~__identifier__~$identifier~g" \
              -e "s~__name__~$name~g" \
              -e "s~__path__~$FOLDER~g" \
              -e "s~__datapath__~$FOLDER/.blueprint/extensions/$identifier/private~g" \
              -e "s~__publicpath__~$EXTPUBDIR~g" \
              -e "s~__installmode__~$INSTALLMODE~g" \
              -e "s~__blueprintversion__~$VERSION~g" \
              -e "s~__timestamp__~$installation_timestamp~g" \
              -e "s~__componentroot__~@/blueprint/extensions/$identifier~g" \
              "$file"
          fi
        elif [ -d "$file" ]; then
          PLACE_PLACEHOLDERS "$file"
        fi
      done
    }
    PLACE_PLACEHOLDERS "$DIR"
  fi

  if [[ $name == "" ]]; then rm -R ".blueprint/tmp/$n";                 PRINT FATAL "'info_name' is a required configuration option.";exit 1;fi
  if [[ $identifier == "" ]]; then rm -R ".blueprint/tmp/$n";           PRINT FATAL "'info_identifier' is a required configuration option.";exit 1;fi
  if [[ $description == "" ]]; then rm -R ".blueprint/tmp/$n";          PRINT FATAL "'info_description' is a required configuration option.";exit 1;fi
  if [[ $version == "" ]]; then rm -R ".blueprint/tmp/$n";              PRINT FATAL "'info_version' is a required configuration option.";exit 1;fi
  if [[ $target == "" ]]; then rm -R ".blueprint/tmp/$n";               PRINT FATAL "'info_target' is a required configuration option.";exit 1;fi
  if [[ $admin_view == "" ]]; then rm -R ".blueprint/tmp/$n";           PRINT FATAL "'admin_view' is a required configuration option.";exit 1;fi
  
  if [[ $icon == "" ]]; then                                            PRINT WARNING "This extension does not come with an icon, consider adding one.";fi
  if [[ $target != "$VERSION" ]]; then                                  PRINT WARNING "This extension is built for version $target, but your version is $VERSION.";fi
  if [[ $identifier != "$n" ]]; then rm -R ".blueprint/tmp/$n";         PRINT FATAL "Extension file name must be the same as your identifier. (example: identifier.blueprint)";exit 1;fi
  if ! [[ $identifier =~ [a-z] ]]; then rm -R ".blueprint/tmp/$n";      PRINT FATAL "Extension identifier should be lowercase and only contain characters a-z.";exit 1;fi
  if [[ $identifier == "blueprint" ]]; then rm -R ".blueprint/tmp/$n";  PRINT FATAL "Extensions can not have the identifier 'blueprint'.";exit 1;fi

  # Validate paths to files and directories defined in conf.yml.
  if [[ ( ! -f ".blueprint/tmp/$n/$icon"                 ) && ( ${icon} != ""                 ) ]] ||    # file:   icon                 (optional)
     [[ ( ! -f ".blueprint/tmp/$n/$admin_view"           )                                      ]] ||    # file:   admin_view
     [[ ( ! -f ".blueprint/tmp/$n/$admin_controller"     ) && ( ${admin_controller} != ""     ) ]] ||    # file:   admin_controller     (optional)
     [[ ( ! -f ".blueprint/tmp/$n/$admin_css"            ) && ( ${admin_css} != ""            ) ]] ||    # file:   admin_css            (optional)
     [[ ( ! -f ".blueprint/tmp/$n/$admin_wrapper"        ) && ( ${admin_wrapper} != ""        ) ]] ||    # file:   admin_wrapper        (optional)
     [[ ( ! -f ".blueprint/tmp/$n/$dashboard_css"        ) && ( ${dashboard_css} != ""        ) ]] ||    # file:   dashboard_css        (optional)
     [[ ( ! -f ".blueprint/tmp/$n/$dashboard_wrapper"    ) && ( ${dashboard_wrapper} != ""    ) ]] ||    # file:   dashboard_wrapper    (optional)
     [[ ( ! -d ".blueprint/tmp/$n/$dashboard_components" ) && ( ${dashboard_components} != "" ) ]] ||    # folder: dashboard_components (optional)
     [[ ( ! -d ".blueprint/tmp/$n/$data_directory"       ) && ( ${data_directory} != ""       ) ]] ||    # folder: data_directory       (optional)
     [[ ( ! -d ".blueprint/tmp/$n/$data_public"          ) && ( ${data_public} != ""          ) ]] ||    # folder: data_public          (optional)
     [[ ( ! -d ".blueprint/tmp/$n/$data_migrations"      ) && ( ${data_migrations} != ""      ) ]];then  # folder: data_migrations      (optional)
    rm -R ".blueprint/tmp/$n"
    PRINT FATAL "Extension configuration points towards one or more files that do not exist."
    exit 1
  fi

  # Validate custom script paths.
  if [[ $F_hasInstallScript == true || $F_hasRemovalScript == true || $F_hasExportScript == true ]]; then
    if [[ $data_directory == "" ]]; then
      rm -R ".blueprint/tmp/$n"
      PRINT FATAL "Install/Remove/Export script requires private folder to be enabled."
      exit 1
    fi

    if [[ $F_hasInstallScript == true ]] && [[ ! -f ".blueprint/tmp/$n/$data_directory/install.sh" ]] ||
       [[ $F_hasRemovalScript == true ]] && [[ ! -f ".blueprint/tmp/$n/$data_directory/remove.sh"  ]] ||
       [[ $F_hasExportScript  == true ]] && [[ ! -f ".blueprint/tmp/$n/$data_directory/export.sh"  ]]; then
      rm -R ".blueprint/tmp/$n"
      PRINT FATAL "Install/Remove/Export script could not be found or detected, even though enabled."
      exit 1
    fi
  fi

  # Place database migrations.
  if [[ $database_migrations != "" ]]; then
    PRINT INFO "Cloning database migration files.."
    cp -R ".blueprint/tmp/$n/$database_migrations/"* "database/migrations/" 2>> $BLUEPRINT__DEBUG
  fi

  # Create, link and connect components directory.
  if [[ $dashboard_components != "" ]]; then
    YARN="y"
    PRINT INFO "Cloning and linking components directory.."
    mkdir -p ".blueprint/extensions/$identifier/components"
    
    cd $FOLDER/resources/scripts/blueprint/extensions || cdhalt
    ln -s -T $FOLDER/.blueprint/extensions/"$identifier"/components "$identifier" 2>> $BLUEPRINT__DEBUG
    cd $FOLDER || cdhalt

    # Remove custom routes to prevent duplicates.
    if [[ $DUPLICATE == "y" ]]; then
      sed -i \
        -e "s/\/\* ${identifier^}ImportStart \*\/.*\/\* ${identifier^}ImportEnd \*\///" \
        -e "s~/\* ${identifier^}ImportStart \*/~~g" \
        -e "s~/\* ${identifier^}ImportEnd \*/~~g" \
        \
        -e "s/\/\* ${identifier^}AccountRouteStart \*\/.*\/\* ${identifier^}AccountRouteEnd \*\///" \
        -e "s~/\* ${identifier^}AccountRouteStart \*~~g" \
        -e "s~/\* ${identifier^}AccountRouteEnd \*~~g" \
        \
        -e "s/\/\* ${identifier^}ServerRouteStart \*\/.*\/\* ${identifier^}ServerRouteEnd \*\///" \
        -e "s~/\* ${identifier^}ServerRouteStart \*~~g" \
        -e "s~/\* ${identifier^}ServerRouteEnd \*~~g" \
        \
        "resources/scripts/blueprint/extends/routers/routes.ts"
    fi

    cp -R ".blueprint/tmp/$n/$dashboard_components/"* ".blueprint/extensions/$identifier/components/" 2>> $BLUEPRINT__DEBUG
    if [[ -f ".blueprint/tmp/$n/$dashboard_components/Components.yml" ]]; then

      # fetch component config
      eval "$(parse_yaml .blueprint/tmp/"$n"/"$dashboard_components"/Components.yml Components_)"
      if [[ $DUPLICATE == "y" ]]; then eval "$(parse_yaml .blueprint/extensions/"${identifier}"/private/.store/Components.yml OldComponents_)"; fi

      # define static variables to make stuff a bit easier
      im="\/\* blueprint\/import \*\/"; re="{/\* blueprint\/react \*/}"; co="resources/scripts/blueprint/components"
      s="import ${identifier^}Component from '"; e="';"

      PLACE_REACT() {
        if [[ 
          ( $1 == "/"* ) || 
          ( $1 == *"/.."* ) || 
          ( $1 == *"../"* ) || 
          ( $1 == *"/../"* ) || 
          ( $1 == *"\n"* ) || 
          ( $1 == *"@"* ) || 
          ( $1 == *"\\"* )
        ]]; then 
          rm -R ".blueprint/tmp/$n"
          PRINT FATAL "Component file paths cannot escape the components folder."
          exit 1
        fi

        if [[ $3 != "$1" ]]; then
          # remove old components
          sed -i "s~""${s}@/blueprint/extensions/${identifier}/$3${e}""~~g" "$co"/"$2"
          sed -i "s~""<${identifier^}Component />""~~g" "$co"/"$2"
        fi
        if [[ ! $1 == "" ]]; then

          # validate file name
          if [[ ${1} == *".tsx" ]] ||
             [[ ${1} == *".ts"  ]] ||
             [[ ${1} == *".jsx" ]] ||
             [[ ${1} == *".js"  ]]; then 
            rm -R ".blueprint/tmp/$n"
            PRINT FATAL "Component paths may not end with a file extension."
            exit 1
          fi

          # validate path
          if [[ ! -f ".blueprint/tmp/$n/$dashboard_components/${1}.tsx" ]] &&
             [[ ! -f ".blueprint/tmp/$n/$dashboard_components/${1}.ts"  ]] &&
             [[ ! -f ".blueprint/tmp/$n/$dashboard_components/${1}.jsx" ]] &&
             [[ ! -f ".blueprint/tmp/$n/$dashboard_components/${1}.js"  ]]; then 
            rm -R ".blueprint/tmp/$n"
            PRINT FATAL "Components configuration points towards one or more files that do not exist."
            exit 1
          fi

          # Purge and add components.
          sed -i \
            -e "s~""${s}@/blueprint/extensions/${identifier}/$1${e}""~~g" \
            -e "s~""<${identifier^}Component />""~~g" \
            \
            -e "s~""$im""~""${im}${s}@/blueprint/extensions/${identifier}/$1${e}""~g" \
            -e "s~""$re""~""${re}\<${identifier^}Component /\>""~g" \
            "$co"/"$2"
        fi
      }

      # place component items
      # -> PLACE_REACT "$Components_" "path/.tsx" "$OldComponents_"


      # navigation
      PLACE_REACT "$Components_Navigation_NavigationBar_BeforeNavigation" "Navigation/NavigationBar/BeforeNavigation.tsx" "$OldComponents_Navigation_NavigationBar_BeforeNavigation"
      PLACE_REACT "$Components_Navigation_NavigationBar_AdditionalItems" "Navigation/NavigationBar/AdditionalItems.tsx" "$OldComponents_Navigation_NavigationBar_AdditionalItems"
      PLACE_REACT "$Components_Navigation_NavigationBar_AfterNavigation" "Navigation/NavigationBar/AfterNavigation.tsx" "$OldComponents_Navigation_NavigationBar_AfterNavigation"
      PLACE_REACT "$Components_Navigation_SubNavigation_BeforeSubNavigation" "Navigation/SubNavigation/BeforeSubNavigation.tsx" "$OldComponents_Navigation_SubNavigation_BeforeSubNavigation"
      PLACE_REACT "$Components_Navigation_SubNavigation_AdditionalServerItems" "Navigation/SubNavigation/AdditionalServerItems.tsx" "$OldComponents_Navigation_SubNavigation_AdditionalServerItems"
      PLACE_REACT "$Components_Navigation_SubNavigation_AdditionalAccountItems" "Navigation/SubNavigation/AdditionalAccountItems.tsx" "$OldComponents_Navigation_SubNavigation_AdditionalAccountItems"
      PLACE_REACT "$Components_Navigation_SubNavigation_AfterSubNavigation" "Navigation/SubNavigation/AfterSubNavigation.tsx" "$OldComponents_Navigation_SubNavigation_AfterSubNavigation"

      # dashboard
      PLACE_REACT "$Components_Dashboard_ServerRow_BeforeEntryName" "Dashboard/ServerRow/BeforeEntryName.tsx" "$OldComponents_Dashboard_ServerRow_BeforeEntryName"
      PLACE_REACT "$Components_Dashboard_ServerRow_AfterEntryName" "Dashboard/ServerRow/AfterEntryName.tsx" "$OldComponents_Dashboard_ServerRow_AfterEntryName"
      PLACE_REACT "$Components_Dashboard_ServerRow_BeforeEntryDescription" "Dashboard/ServerRow/BeforeEntryDescription.tsx" "$OldComponents_Dashboard_ServerRow_BeforeEntryDescription"
      PLACE_REACT "$Components_Dashboard_ServerRow_AfterEntryDescription" "Dashboard/ServerRow/AfterEntryDescription.tsx" "$OldComponents_Dashboard_ServerRow_AfterEntryDescription"
      PLACE_REACT "$Components_Dashboard_ServerRow_ResourceLimits" "Dashboard/ServerRow/ResourceLimits.tsx" "$OldComponents_Dashboard_ServerRow_ResourceLimits"

      # authentication
      PLACE_REACT "$Components_Authentication_Container_BeforeContent" "Authentication/Container/BeforeContent.tsx" "$OldComponents_Authentication_Container_BeforeContent"
      PLACE_REACT "$Components_Authentication_Container_AfterContent" "Authentication/Container/AfterContent.tsx" "$OldComponents_Authentication_Container_AfterContent"

      # server
      PLACE_REACT "$Components_Server_Terminal_BeforeContent" "Server/Terminal/BeforeContent.tsx" "$OldComponents_Server_Terminal_BeforeContent"
      PLACE_REACT "$Components_Server_Terminal_AfterContent" "Server/Terminal/AfterContent.tsx" "$OldComponents_Server_Terminal_AfterContent"

      PLACE_REACT "$Components_Server_Files_Browse_BeforeContent" "Server/Files/Browse/BeforeContent.tsx" "$OldComponents_Server_Files_Browse_BeforeContent"
      PLACE_REACT "$Components_Server_Files_Browse_FileButtons" "Server/Files/Browse/FileButtons.tsx" "$OldComponents_Server_Files_Browse_FileButtons"
      PLACE_REACT "$Components_Server_Files_Browse_DropdownItems" "Server/Files/Browse/DropdownItems.tsx" "$OldComponents_Server_Files_Browse_DropdownItems"
      PLACE_REACT "$Components_Server_Files_Browse_AfterContent" "Server/Files/Browse/AfterContent.tsx" "$OldComponents_Server_Files_Browse_AfterContent"
      PLACE_REACT "$Components_Server_Files_Edit_BeforeEdit" "Server/Files/Edit/BeforeEdit.tsx" "$OldComponents_Server_Files_Edit_BeforeEdit"
      PLACE_REACT "$Components_Server_Files_Edit_AfterEdit" "Server/Files/Edit/AfterEdit.tsx" "$OldComponents_Server_Files_Edit_AfterEdit"
      
      PLACE_REACT "$Components_Server_Databases_BeforeContent" "Server/Databases/BeforeContent.tsx" "$OldComponents_Server_Databases_BeforeContent"
      PLACE_REACT "$Components_Server_Databases_AfterContent" "Server/Databases/AfterContent.tsx" "$OldComponents_Server_Databases_AfterContent"

      PLACE_REACT "$Components_Server_Schedules_List_BeforeContent" "Server/Schedules/List/BeforeContent.tsx" "$OldComponents_Server_Schedules_List_BeforeContent"
      PLACE_REACT "$Components_Server_Schedules_List_AfterContent" "Server/Schedules/List/AfterContent.tsx" "$OldComponents_Server_Schedules_List_AfterContent"
      PLACE_REACT "$Components_Server_Schedules_Edit_BeforeEdit" "Server/Schedules/Edit/BeforeEdit.tsx" "$OldComponents_Server_Schedules_Edit_BeforeEdit"
      PLACE_REACT "$Components_Server_Schedules_Edit_AfterEdit" "Server/Schedules/Edit/AfterEdit.tsx" "$OldComponents_Server_Schedules_Edit_AfterEdit"

      PLACE_REACT "$Components_Server_Users_BeforeContent" "Server/Users/BeforeContent.tsx" "$OldComponents_Server_Users_BeforeContent"
      PLACE_REACT "$Components_Server_Users_AfterContent" "Server/Users/AfterContent.tsx" "$OldComponents_Server_Users_AfterContent"

      PLACE_REACT "$Components_Server_Backups_BeforeContent" "Server/Backups/BeforeContent.tsx" "$OldComponents_Server_Backups_BeforeContent"
      PLACE_REACT "$Components_Server_Backups_DropdownItems" "Server/Backups/DropdownItems.tsx" "$OldComponents_Server_Backups_DropdownItems"
      PLACE_REACT "$Components_Server_Backups_AfterContent" "Server/Backups/AfterContent.tsx" "$OldComponents_Server_Backups_AfterContent"

      PLACE_REACT "$Components_Server_Network_BeforeContent" "Server/Network/BeforeContent.tsx" "$OldComponents_Server_Network_BeforeContent"
      PLACE_REACT "$Components_Server_Network_AfterContent" "Server/Network/AfterContent.tsx" "$OldComponents_Server_Network_AfterContent"

      PLACE_REACT "$Components_Server_Startup_BeforeContent" "Server/Startup/BeforeContent.tsx" "$OldComponents_Server_Startup_BeforeContent"
      PLACE_REACT "$Components_Server_Startup_AfterContent" "Server/Startup/AfterContent.tsx" "$OldComponents_Server_Startup_AfterContent"

      PLACE_REACT "$Components_Server_Settings_BeforeContent" "Server/Settings/BeforeContent.tsx" "$OldComponents_Server_Settings_BeforeContent"
      PLACE_REACT "$Components_Server_Settings_AfterContent" "Server/Settings/AfterContent.tsx" "$OldComponents_Server_Settings_AfterContent"

      # account
      PLACE_REACT "$Components_Account_Overview_BeforeContent" "Account/Overview/BeforeContent.tsx" "$OldComponents_Account_Overview_BeforeContent"
      PLACE_REACT "$Components_Account_Overview_AfterContent" "Account/Overview/AfterContent.tsx" "$OldComponents_Account_Overview_AfterContent"

      PLACE_REACT "$Components_Account_API_BeforeContent" "Account/API/BeforeContent.tsx" "$OldComponents_Account_API_BeforeContent"
      PLACE_REACT "$Components_Account_API_AfterContent" "Account/API/AfterContent.tsx" "$OldComponents_Account_API_AfterContent"

      PLACE_REACT "$Components_Account_SSH_BeforeContent" "Account/SSH/BeforeContent.tsx" "$OldComponents_Account_SSH_BeforeContent"
      PLACE_REACT "$Components_Account_SSH_AfterContent" "Account/SSH/AfterContent.tsx" "$OldComponents_Account_SSH_AfterContent"



      # Place custom extension routes.
      if [[ $Components_Navigation_Routes_ != "" ]]; then
        PRINT INFO "Linking navigation routes.."

        ImportConstructor=".blueprint/extensions/blueprint/private/build/extensions/routes/importConstructor.bak"
        AccountRouteConstructor=".blueprint/extensions/blueprint/private/build/extensions/routes/accountRouteConstructor.bak"
        ServerRouteConstructor=".blueprint/extensions/blueprint/private/build/extensions/routes/serverRouteConstructor.bak"
        
        {
          cp ".blueprint/extensions/blueprint/private/build/extensions/routes/importConstructor" "$ImportConstructor"
          cp ".blueprint/extensions/blueprint/private/build/extensions/routes/accountRouteConstructor" "$AccountRouteConstructor"
          cp ".blueprint/extensions/blueprint/private/build/extensions/routes/serverRouteConstructor" "$ServerRouteConstructor"
        } 2>> $BLUEPRINT__DEBUG

        sed -i "s~\[id\^]~""${identifier^}""~g" $ImportConstructor
        sed -i "s~\[id\^]~""${identifier^}""~g" $AccountRouteConstructor
        sed -i "s~\[id\^]~""${identifier^}""~g" $ServerRouteConstructor

        for parent in $Components_Navigation_Routes_; do
          parent="${parent}_"
          for child in ${!parent}; do
            # Route name
            if [[ $child == "Components_Navigation_Routes_"+([0-9])"_Name" ]]; then COMPONENTS_ROUTE_NAME="${!child}"; fi
            # Route path
            if [[ $child == "Components_Navigation_Routes_"+([0-9])"_Path" ]]; then COMPONENTS_ROUTE_PATH="${!child}"; fi
            # Route type
            if [[ $child == "Components_Navigation_Routes_"+([0-9])"_Type" ]]; then COMPONENTS_ROUTE_TYPE="${!child}"; fi
            # Route component
            if [[ $child == "Components_Navigation_Routes_"+([0-9])"_Component" ]]; then COMPONENTS_ROUTE_COMP="${!child}"; fi
          done

          # Route identifier
          COMPONENTS_ROUTE_IDEN=$(tr -dc '[:lower:]' < /dev/urandom | fold -w 10 | head -n 1)
          COMPONENTS_ROUTE_IDEN="${identifier^}${COMPONENTS_ROUTE_IDEN^}"

          echo -e "NAME: $COMPONENTS_ROUTE_NAME\nPATH: $COMPONENTS_ROUTE_PATH\nTYPE: $COMPONENTS_ROUTE_TYPE\nCOMP: $COMPONENTS_ROUTE_COMP\nIDEN: $COMPONENTS_ROUTE_IDEN" >> $BLUEPRINT__DEBUG


          # Return error if type is not defined correctly.
          if [[ ( $COMPONENTS_ROUTE_TYPE != "server" ) && ( $COMPONENTS_ROUTE_TYPE != "account" ) ]]; then
            rm -R ".blueprint/tmp/$n"
            PRINT FATAL "Navigation route types can only be either 'server' or 'account'."
            exit 1
          fi

          # Prevent escaping components folder.
          if [[ 
            ( ${COMPONENTS_ROUTE_COMP} == "/"* ) || 
            ( ${COMPONENTS_ROUTE_COMP} == *"/.."* ) || 
            ( ${COMPONENTS_ROUTE_COMP} == *"../"* ) || 
            ( ${COMPONENTS_ROUTE_COMP} == *"/../"* ) || 
            ( ${COMPONENTS_ROUTE_COMP} == *"\n"* ) || 
            ( ${COMPONENTS_ROUTE_COMP} == *"@"* ) || 
            ( ${COMPONENTS_ROUTE_COMP} == *"\\"* )
          ]]; then 
            rm -R ".blueprint/tmp/$n"
            PRINT FATAL "Navigation route component paths may not escape the components directory."
            exit 1
          fi

          # Validate file names for route components.
          if [[ ${COMPONENTS_ROUTE_COMP} == *".tsx" ]] \
          || [[ ${COMPONENTS_ROUTE_COMP} == *".ts"  ]] \
          || [[ ${COMPONENTS_ROUTE_COMP} == *".jsx" ]] \
          || [[ ${COMPONENTS_ROUTE_COMP} == *".js"  ]]; then 
            rm -R ".blueprint/tmp/$n"
            PRINT FATAL "Navigation route component paths may not end with a file extension."
            exit 1
          fi

          # Validate file path.
          if [[ ! -f ".blueprint/tmp/$n/$dashboard_components/${COMPONENTS_ROUTE_COMP}.tsx" ]] \
          && [[ ! -f ".blueprint/tmp/$n/$dashboard_components/${COMPONENTS_ROUTE_COMP}.ts"  ]] \
          && [[ ! -f ".blueprint/tmp/$n/$dashboard_components/${COMPONENTS_ROUTE_COMP}.jsx" ]] \
          && [[ ! -f ".blueprint/tmp/$n/$dashboard_components/${COMPONENTS_ROUTE_COMP}.js"  ]]; then 
            rm -R ".blueprint/tmp/$n"
            PRINT FATAL "Navigation route configuration points towards one or more components that do not exist."
            exit 1
          fi

          # Return error if identifier is generated incorrectly.
          if [[ $COMPONENTS_ROUTE_IDEN == "" ]]; then
            rm -R ".blueprint/tmp/$n"
            PRINT FATAL "Failed to generate extension navigation route identifier, halting process."
            exit 1
          fi

          # Return error if routes are defined incorrectly.
          if [[ $COMPONENTS_ROUTE_NAME == "" ]] \
          || [[ $COMPONENTS_ROUTE_PATH == "" ]] \
          || [[ $COMPONENTS_ROUTE_TYPE == "" ]] \
          || [[ $COMPONENTS_ROUTE_COMP == "" ]]; then
            rm -R ".blueprint/tmp/$n"
            PRINT FATAL "One or more extension navigation routes appear to have undefined fields."
            exit 1
          fi


          # Apply routes.
          if [[ $COMPONENTS_ROUTE_TYPE == "account" ]]; then
            # Account routes
            COMPONENTS_IMPORT="import $COMPONENTS_ROUTE_IDEN from '@/blueprint/extensions/$identifier/$COMPONENTS_ROUTE_COMP';"
            COMPONENTS_ROUTE="{ path: '$COMPONENTS_ROUTE_PATH', name: '$COMPONENTS_ROUTE_NAME', component: $COMPONENTS_ROUTE_IDEN, },"

            sed -i "s~/\* \[import] \*/~/* [import] */""$COMPONENTS_IMPORT""~g" $ImportConstructor
            sed -i "s~/\* \[routes] \*/~/* [routes] */""$COMPONENTS_ROUTE""~g" $AccountRouteConstructor
          elif [[ $COMPONENTS_ROUTE_TYPE == "server" ]]; then
            # Server routes
            COMPONENTS_IMPORT="import $COMPONENTS_ROUTE_IDEN from '@/blueprint/extensions/$identifier/$COMPONENTS_ROUTE_COMP';"
            COMPONENTS_ROUTE="{ path: '$COMPONENTS_ROUTE_PATH', permission: null, name: '$COMPONENTS_ROUTE_NAME', component: $COMPONENTS_ROUTE_IDEN, },"

            sed -i "s~/\* \[import] \*/~/* [import] */""$COMPONENTS_IMPORT""~g" $ImportConstructor
            sed -i "s~/\* \[routes] \*/~/* [routes] */""$COMPONENTS_ROUTE""~g" $ServerRouteConstructor
          fi 

          # Clear variables after doing all route stuff for a defined route.
          COMPONENTS_ROUTE=""
          COMPONENTS_IMPORT=""

          COMPONENTS_ROUTE_NAME=""
          COMPONENTS_ROUTE_PATH=""
          COMPONENTS_ROUTE_TYPE=""
          COMPONENTS_ROUTE_COMP=""
          COMPONENTS_ROUTE_IDEN=""
        done

        sed -i "s~/\* \[import] \*/~~g" $ImportConstructor
        sed -i "s~/\* \[routes] \*/~~g" $AccountRouteConstructor
        sed -i "s~/\* \[routes] \*/~~g" $ServerRouteConstructor

        sed -i \
          -e "s~\/\* blueprint\/import \*\/~/* blueprint/import */""$(tr '\n' '\001' <${ImportConstructor})""~g" \
          -e "s~\/\* routes/account \*\/~/* routes/account */""$(tr '\n' '\001' <${AccountRouteConstructor})""~g" \
          -e "s~\/\* routes/server \*\/~/* routes/server */""$(tr '\n' '\001' <${ServerRouteConstructor})""~g" \
          "resources/scripts/blueprint/extends/routers/routes.ts"

        # Fix line breaks by removing all of them.
        sed -i -E "s~~~g" "resources/scripts/blueprint/extends/routers/routes.ts"
        
        {
          rm "$ImportConstructor"
          rm "$AccountRouteConstructor"
          rm "$ServerRouteConstructor"
        } 2>> $BLUEPRINT__DEBUG
      fi
    else
      # warn about missing components.yml file
      PRINT WARNING "Could not find '$dashboard_components/Components.yml', component extendability might be limited."
    fi
  fi

  # Create and link public directory.
  if [[ $data_public != "" ]]; then
    PRINT INFO "Cloning and linking public directory.."
    mkdir -p ".blueprint/extensions/$identifier/public"
    
    cd $FOLDER/public/extensions || cdhalt
    ln -s -T $FOLDER/.blueprint/extensions/"$identifier"/public "$identifier" 2>> $BLUEPRINT__DEBUG
    cd $FOLDER || cdhalt

    cp -R ".blueprint/tmp/$n/$data_public/"* ".blueprint/extensions/$identifier/public/" 2>> $BLUEPRINT__DEBUG
  fi

  if [[ $admin_controller == "" ]]; then
    controller_type="default"
  else 
    controller_type="custom"
  fi

  # Prepare build files.
  AdminControllerConstructor=".blueprint/extensions/blueprint/private/build/extensions/controller.build.bak"
  AdminBladeConstructor=".blueprint/extensions/blueprint/private/build/extensions/admin.blade.php.bak"
  AdminRouteConstructor=".blueprint/extensions/blueprint/private/build/extensions/route.php.bak"
  AdminButtonConstructor=".blueprint/extensions/blueprint/private/build/extensions/button.blade.php.bak"

  {
    if [[ $controller_type == "default" ]]; then cp ".blueprint/extensions/blueprint/private/build/extensions/controller.build" "$AdminControllerConstructor"; fi
    cp ".blueprint/extensions/blueprint/private/build/extensions/admin.blade.php" "$AdminBladeConstructor"
    cp ".blueprint/extensions/blueprint/private/build/extensions/route.php" "$AdminRouteConstructor"
    cp ".blueprint/extensions/blueprint/private/build/extensions/button.blade.php" "$AdminButtonConstructor"
  } 2>> $BLUEPRINT__DEBUG;


  # Start creating data directory.
  PRINT INFO "Cloning and linking private directory.."
  mkdir -p \
    ".blueprint/extensions/$identifier/private" \
    ".blueprint/extensions/$identifier/private/.store"
  
  if [[ $data_directory != "" ]]; then cp -R ".blueprint/tmp/$n/$data_directory/"* ".blueprint/extensions/$identifier/private/"; fi

  cp ".blueprint/tmp/$n/conf.yml" ".blueprint/extensions/$identifier/private/.store/conf.yml" #backup conf.yml
  if [[ -f ".blueprint/tmp/$n/$dashboard_components/Components.yml" ]]; then
    cp ".blueprint/tmp/$n/$dashboard_components/Components.yml" ".blueprint/extensions/$identifier/private/.store/Components.yml" #backup Components.yml
  fi
  # End creating data directory.


  # Link and create assets folder
  PRINT INFO "Linking and writing assets directory.."
  if [[ $DUPLICATE != "y" ]]; then
    # Create assets folder if the extension is not updating.
    mkdir .blueprint/extensions/"$identifier"/assets
  fi
  cd $FOLDER/public/assets/extensions || cdhalt
  ln -s -T $FOLDER/.blueprint/extensions/"$identifier"/assets "$identifier" 2>> $BLUEPRINT__DEBUG
  cd $FOLDER || cdhalt
  
  if [[ $icon == "" ]]; then
    # use random placeholder icon if extension does not
    # come with an icon.
    icnNUM=$(( 1 + RANDOM % 5 ))
    cp ".blueprint/assets/defaultExtensionLogo$icnNUM.jpg" ".blueprint/extensions/$identifier/assets/icon.jpg"
  else
    cp ".blueprint/tmp/$n/$icon" ".blueprint/extensions/$identifier/assets/icon.jpg"
  fi;
  ICON="/assets/extensions/$identifier/icon.jpg"
  CONTENT=$(cat .blueprint/tmp/"$n"/"$admin_view")

  if [[ $admin_css != "" ]]; then
    PRINT INFO "Cloning and linking admin css.."
    updateCacheReminder
    sed -i "s~@import url(/assets/extensions/$identifier/admin.style.css);~~g" ".blueprint/extensions/blueprint/assets/admin.extensions.css"
    echo -e "@import url(/assets/extensions/$identifier/admin.style.css);" >> ".blueprint/extensions/blueprint/assets/admin.extensions.css"
    cp ".blueprint/tmp/$n/$admin_css" ".blueprint/extensions/$identifier/assets/admin.style.css"
  fi
  if [[ $dashboard_css != "" ]]; then
    PRINT INFO "Cloning and linking dashboard css.."
    YARN="y"
    sed -i "s~@import url(./imported/$identifier.css);~~g" "resources/scripts/blueprint/css/extensions.css"
    echo -e "@import url(./imported/$identifier.css);" >> "resources/scripts/blueprint/css/extensions.css"
    cp ".blueprint/tmp/$n/$dashboard_css" "resources/scripts/blueprint/css/imported/$identifier.css"
  fi

  if [[ $name == *"~"* ]]; then        PRINT WARNING "'name' contains '~' and may result in an error.";fi
  if [[ $description == *"~"* ]]; then PRINT WARNING "'description' contains '~' and may result in an error.";fi
  if [[ $version == *"~"* ]]; then     PRINT WARNING "'version' contains '~' and may result in an error.";fi
  if [[ $CONTENT == *"~"* ]]; then     PRINT WARNING "'CONTENT' contains '~' and may result in an error.";fi
  if [[ $ICON == *"~"* ]]; then        PRINT WARNING "'ICON' contains '~' and may result in an error.";fi
  if [[ $identifier == *"~"* ]]; then  PRINT WARNING "'identifier' contains '~' and may result in an error.";fi

  # Construct admin button
  sed -i \
    -e "s~\[name\]~$name~g" \
    -e "s~\[version\]~$version~g" \
    -e "s~\[id\]~$identifier~g" \
    "$AdminButtonConstructor"

  # Construct admin view
  sed -i \
    -e "s~\[name\]~$name~g" \
    -e "s~\[description\]~$description~g" \
    -e "s~\[version\]~$version~g" \
    -e "s~\[icon\]~$ICON~g" \
    "$AdminBladeConstructor"
  if [[ $website != "" ]]; then
    sed -i \
      -e "s~\[website\]~$website~g" \
      -e "s~<!--\[web\] ~~g" \
      -e "s~ \[web\]-->~~g" \
      -e "s~\[webicon\]~$websiteiconclass~g" \
      "$AdminBladeConstructor"
  fi
  echo -e "$CONTENT\n@endsection" >> "$AdminBladeConstructor"

  # Construct admin route
  sed -i "s~\[id\]~$identifier~g" "$AdminRouteConstructor"

  # Construct admin controller
  if [[ $controller_type == "default" ]]; then sed -i "s~\[id\]~$identifier~g" "$AdminControllerConstructor"; fi


  # Read final results.
  ADMINVIEW_RESULT=$(<"$AdminBladeConstructor")
  ADMINROUTE_RESULT=$(<"$AdminRouteConstructor")
  ADMINBUTTON_RESULT=$(<"$AdminButtonConstructor")
  if [[ $controller_type == "default" ]]; then
    ADMINCONTROLLER_RESULT=$(<"$AdminControllerConstructor")
  fi
  ADMINCONTROLLER_NAME="${identifier}ExtensionController.php"

  # Place admin extension view.
  PRINT INFO "Cloning admin view.."
  mkdir -p "resources/views/admin/extensions/$identifier"
  touch "resources/views/admin/extensions/$identifier/index.blade.php"
  echo "$ADMINVIEW_RESULT" > "resources/views/admin/extensions/$identifier/index.blade.php"

  # Place admin extension view controller.
  PRINT INFO "Cloning admin controller.."
  mkdir -p "app/Http/Controllers/Admin/Extensions/$identifier"
  touch "app/Http/Controllers/Admin/Extensions/$identifier/$ADMINCONTROLLER_NAME"
  if [[ $controller_type == "default" ]]; then
    # Use custom view controller.
    touch "app/Http/Controllers/Admin/Extensions/$identifier/$ADMINCONTROLLER_NAME"
    echo "$ADMINCONTROLLER_RESULT" > "app/Http/Controllers/Admin/Extensions/$identifier/$ADMINCONTROLLER_NAME"
  else
    # Use default extension controller.
    cp .blueprint/tmp/"$n"/"$admin_controller" "app/Http/Controllers/Admin/Extensions/$identifier/$ADMINCONTROLLER_NAME"
  fi

  if [[ $DUPLICATE != "y" ]]; then
    # Place admin route if extension is not updating.
    PRINT INFO "Editing admin routes.."
    { echo "
    // $identifier:start";
    echo "$ADMINROUTE_RESULT";
    echo // "$identifier":stop; } >> "routes/admin.php"
  else
    # Replace old extensions page button if extension is updating.
    OLDBUTTON_RESULT=$(<.blueprint/extensions/"$identifier"/private/.store/build/button.blade.php)
    sed -i "s~$OLDBUTTON_RESULT~~g" "resources/views/admin/extensions.blade.php"
  fi
  sed -i "s~<!-- \[entryplaceholder\] -->~$ADMINBUTTON_RESULT\n<!-- \[entryplaceholder\] -->~g" "resources/views/admin/extensions.blade.php"

  # Place dashboard wrapper
  if [[ $dashboard_wrapper != "" ]]; then
    PRINT INFO "Cloning and injecting dashboard wrapper.."
    if [[ $DUPLICATE == "y" ]]; then
      sed -n -i "/<!--␀$identifier:start␀-->/{p; :a; N; /<!--␀$identifier:stop␀-->/!ba; s/.*\n//}; p" "resources/views/templates/wrapper.blade.php"
      sed -i \
        -e "s~<!--␀$identifier:start␀-->~~g" \
        -e "s~<!--␀$identifier:stop␀-->~~g" \
        "resources/views/templates/wrapper.blade.php"
    fi
    touch ".blueprint/tmp/$n/$dashboard_wrapper.BLUEPRINTBAK"
    cat <(echo "<!--␀$identifier:start␀-->") ".blueprint/tmp/$n/$dashboard_wrapper" > ".blueprint/tmp/$n/$dashboard_wrapper.BLUEPRINTBAK"
    cp ".blueprint/tmp/$n/$dashboard_wrapper.BLUEPRINTBAK" ".blueprint/tmp/$n/$dashboard_wrapper"
    rm ".blueprint/tmp/$n/$dashboard_wrapper.BLUEPRINTBAK"
    echo -e "\n<!--␀$identifier:stop␀-->" >> ".blueprint/tmp/$n/$dashboard_wrapper"
    sed -i "/<\!-- wrapper:insert -->/r .blueprint/tmp/$n/$dashboard_wrapper" "resources/views/templates/wrapper.blade.php"
  fi

  # Place admin wrapper
  if [[ $admin_wrapper != "" ]]; then
    PRINT INFO "Cloning and injecting admin wrapper.."
    if [[ $DUPLICATE == "y" ]]; then
      sed -n -i "/<!--␀$identifier:start␀-->/{p; :a; N; /<!--␀$identifier:stop␀-->/!ba; s/.*\n//}; p" "resources/views/layouts/admin.blade.php"
      sed -i \
        -e "s~<!--␀$identifier:start␀-->~~g" \
        -e "s~<!--␀$identifier:stop␀-->~~g" \
        "resources/views/layouts/admin.blade.php"
    fi
    touch ".blueprint/tmp/$n/$admin_wrapper.BLUEPRINTBAK"
    cat <(echo "<!--␀$identifier:start␀-->") ".blueprint/tmp/$n/$admin_wrapper" > ".blueprint/tmp/$n/$admin_wrapper.BLUEPRINTBAK"
    cp ".blueprint/tmp/$n/$admin_wrapper.BLUEPRINTBAK" ".blueprint/tmp/$n/$admin_wrapper"
    rm ".blueprint/tmp/$n/$admin_wrapper.BLUEPRINTBAK"
    echo -e "\n<!--␀$identifier:stop␀-->" >> ".blueprint/tmp/$n/$admin_wrapper"
    sed -i "/<\!-- wrapper:insert -->/r .blueprint/tmp/$n/$admin_wrapper" "resources/views/layouts/admin.blade.php"
  fi

  # Create backup of generated values.
  mkdir -p ".blueprint/extensions/$identifier/private/.store/build"
  cp ".blueprint/extensions/blueprint/private/build/extensions/button.blade.php.bak" ".blueprint/extensions/$identifier/private/.store/build/button.blade.php"
  cp ".blueprint/extensions/blueprint/private/build/extensions/route.php.bak" ".blueprint/extensions/$identifier/private/.store/build/route.php"

  # Remove temporary build files.
  PRINT INFO "Cleaning up build files.."
  if [[ $controller_type == "default" ]]; then rm ".blueprint/extensions/blueprint/private/build/extensions/controller.build.bak"; fi
  rm \
    "$AdminBladeConstructor" \
    "$AdminRouteConstructor" \
    "$AdminButtonConstructor"
  rm -R ".blueprint/tmp/$n"

  if [[ $database_migrations != "" ]]; then
    PRINT INPUT "Would you like to migrate your database? (Y/n)"
    read -r YN
    if [[ ( $YN == "y"* ) || ( $YN == "Y"* ) || ( $YN == "" ) ]]; then 
      PRINT INFO "Running database migrations.."
      php artisan migrate --force
    else
      PRINT INFO "Database migrations have been skipped."
    fi
  fi

  if [[ $YARN == "y" ]]; then 
    if ! [[ ( $F_developerIgnoreRebuild == true ) && ( $dev == true ) ]]; then
      PRINT INFO "Rebuilding panel assets.."
      yarn run build:production
    fi
  fi

  # Flush cache.
  PRINT INFO "Flushing view, config and route cache.."
  {
    php artisan view:clear
    php artisan config:clear
    php artisan route:cache
    php artisan cache:clear
  } &>> $BLUEPRINT__DEBUG 

  chown -R www-data:www-data "$FOLDER/.blueprint/extensions/$identifier/private"
  chmod --silent -R +x ".blueprint/extensions/"* 2>> $BLUEPRINT__DEBUG

  if [[ ( $F_developerIgnoreInstallScript == false ) || ( $dev != true ) ]]; then
    if $F_hasInstallScript; then
      PRINT WARNING "Extension uses a custom installation script, proceed with caution."
      chmod +x ".blueprint/extensions/$identifier/private/install.sh"

      # Run script while also parsing some useful variables for the install script to use.
      EXTENSION_IDENTIFIER="$identifier" \
      EXTENSION_TARGET="$target"         \
      EXTENSION_VERSION="$version"       \
      PTERODACTYL_DIRECTORY="$FOLDER"    \
      BLUEPRINT_VERSION="$VERSION"       \
      BLUEPRINT_DEVELOPER="$dev"         \
      bash ".blueprint/extensions/$identifier/private/install.sh"

      echo -e "\e[0m\x1b[0m\033[0m"
    fi
  fi

  if [[ $DUPLICATE != "y" ]]; then
    PRINT INFO "Adding '$identifier' to active extensions list.."
    echo "${identifier}," >> ".blueprint/extensions/blueprint/private/db/installed_extensions"
  fi

  if [[ $dev != true ]]; then
    if [[ $DUPLICATE == "y" ]]; then
      PRINT SUCCESS "$identifier has been updated."
    else
      PRINT SUCCESS "$identifier has been installed."
    fi
    sendTelemetry "FINISH_EXTENSION_INSTALLATION" >> $BLUEPRINT__DEBUG
  elif [[ $dev == true ]]; then
    PRINT SUCCESS "$identifier has been built."
    sendTelemetry "BUILD_DEVELOPMENT_EXTENSION" >> $BLUEPRINT__DEBUG
  fi

  exit 0 # success
fi

# -r, -remove
if [[ ( $2 == "-r" ) || ( $2 == "-remove" ) ]]; then VCMD="y"
  if [[ $(( $# - 2 )) != 1 ]]; then PRINT FATAL "Expected 1 argument but got $(( $# - 2 )).";exit 2;fi
  
  # Check if the extension is installed.
  if [[ $(cat ".blueprint/extensions/blueprint/private/db/installed_extensions") != *"$3,"* ]]; then
    PRINT FATAL "'$3' is not installed or detected."
    exit 2
  fi

  if [[ -f ".blueprint/extensions/$3/private/.store/conf.yml" ]]; then 
    eval "$(parse_yaml ".blueprint/extensions/$3/private/.store/conf.yml" conf_)"
    # Add aliases for config values to make working with them easier.
    name="$conf_info_name";    
    identifier="$conf_info_identifier"
    description="$conf_info_description"
    flags="$conf_info_flags" #(optional)
    version="$conf_info_version"
    target="$conf_info_target"
    author="$conf_info_author" #(optional)
    icon="$conf_info_icon" #(optional)
    website="$conf_info_website"; #(optional)

    admin_view="$conf_admin_view"
    admin_controller="$conf_admin_controller"; #(optional)
    admin_css="$conf_admin_css"; #(optional)
    admin_wrapper="$conf_admin_wrapper"; #(optional)

    dashboard_css="$conf_dashboard_css"; #(optional)
    dashboard_wrapper="$conf_dashboard_wrapper"; #(optional)
    dashboard_components="$conf_dashboard_components"; #(optional)

    data_directory="$conf_data_directory"; #(optional)
    data_public="$conf_data_public"; #(optional)

    database_migrations="$conf_database_migrations"; #(optional)
  else 
    PRINT FATAL "Backup conf.yml could not be found."
    PRINT FATAL "Extension configuration file not found or detected."
    exit 1
  fi

  PRINT INPUT "Do you want to proceed with this transaction? Some files might not be removed properly. (y/N)"
  read -r YN
  if [[ ( $YN == "n"* ) || ( $YN == "N"* ) || ( $YN == "" ) ]]; then PRINT INFO "Extension removal cancelled.";exit 1;fi

  PRINT INFO "Searching and validating framework dependencies.."
  depend

  # Assign variables to extension flags.
  PRINT INFO "Reading and assigning extension flags.."
  assignflags

  if $F_hasRemovalScript; then
    PRINT WARNING "Extension uses a custom removal script, proceed with caution."
    chmod +x ".blueprint/extensions/$identifier/private/remove.sh"

    # Run script while also parsing some useful variables for the uninstall script to use.
    EXTENSION_IDENTIFIER="$identifier" \
    EXTENSION_TARGET="$target"         \
    EXTENSION_VERSION="$version"       \
    PTERODACTYL_DIRECTORY="$FOLDER"    \
    BLUEPRINT_VERSION="$VERSION"       \
    bash ".blueprint/extensions/$identifier/private/remove.sh"
    
    echo -e "\e[0m\x1b[0m\033[0m"
  fi

  # Remove admin button 
  PRINT INFO "Editing 'extensions' admin page.."
  OLDBUTTON_RESULT=$(cat ".blueprint/extensions/$identifier/private/.store/build/button.blade.php")
  sed -i "s~$OLDBUTTON_RESULT~~g" "resources/views/admin/extensions.blade.php"

  # Remove admin routes
  PRINT INFO "Removing admin routes.."
  sed -n -i "/\/\/ $identifier:start/{p; :a; N; /\/\/ $identifier:stop/!ba; s/.*\n//}; p" "routes/admin.php"
  sed -i \
    -e "s~// $identifier:start~~g" \
    -e "s~// $identifier:stop~~g" \
    "routes/admin.php"
  
  # Remove admin view
  PRINT INFO "Removing admin view directory.."
  rm -r "resources/views/admin/extensions/$identifier"

  # Remove admin controller
  PRINT INFO "Removing admin controller directory.."
  rm -r "app/Http/Controllers/Admin/Extensions/$identifier"

  # Remove admin css
  if [[ $admin_css != "" ]]; then
    PRINT INFO "Removing and unlinking admin css.."
    updateCacheReminder
    sed -i "s~@import url(/assets/extensions/$identifier/admin.style.css);~~g" ".blueprint/extensions/blueprint/assets/admin.extensions.css"
  fi

  # Remove admin wrapper
  if [[ $admin_wrapper != "" ]]; then 
    PRINT INFO "Removing admin wrapper.."
    sed -n -i "/<!--@$identifier:s@-->/{p; :a; N; /<!--@$identifier:e@-->/!ba; s/.*\n//}; p" "resources/views/layouts/admin.blade.php"
    sed -i \
      -e "s~<!--@$identifier:s@-->~~g" \
      -e "s~<!--@$identifier:e@-->~~g" \
      "resources/views/layouts/admin.blade.php"
  fi

  # Remove dashboard wrapper
  if [[ $dashboard_wrapper != "" ]]; then 
    PRINT INFO "Removing dashboard wrapper.."
    sed -n -i "/<!--@$identifier:s@-->/{p; :a; N; /<!--@$identifier:e@-->/!ba; s/.*\n//}; p" "resources/views/templates/wrapper.blade.php"
    sed -i \
      -e "s~<!--@$identifier:s@-->~~g" \
      -e "s~<!--@$identifier:e@-->~~g" \
      "resources/views/templates/wrapper.blade.php"
  fi

  # Remove dashboard css
  if [[ $dashboard_css != "" ]]; then
    PRINT INFO "Removing and unlinking dashboard css.."
    sed -i "s~@import url(./imported/$identifier.css);~~g" "resources/scripts/blueprint/css/extensions.css"
    rm "resources/scripts/blueprint/css/imported/$identifier.css"
    YARN="y"
  fi

  # Remove dashboard components
  if [[ $dashboard_components != "" ]]; then
    PRINT INFO "Removing and unlinking dashboard components.."
    # fetch component config
    eval "$(parse_yaml .blueprint/extensions/"$identifier"/components/Components.yml Components_)"

    # define static variables to make stuff a bit easier
    im="\/\* blueprint\/import \*\/"; re="{/\* blueprint\/react \*/}"; co="resources/scripts/blueprint/components"
    s="import ${identifier^}Component from '"; e="';"

    REMOVE_REACT() {
      if [[ ! $1 == "" ]]; then
        # remove components
        sed -i \
          -e "s~""${s}@/blueprint/extensions/${identifier}/$1${e}""~~g" \
          -e "s~""<${identifier^}Component />""~~g" \
          "$co"/"$2"
      fi
    }

    # remove component items
    # -> REMOVE_REACT "$Components_" "path/.tsx" "$OldComponents_"


    # navigation
    REMOVE_REACT "$Components_Navigation_NavigationBar_BeforeNavigation" "Navigation/NavigationBar/BeforeNavigation.tsx"
    REMOVE_REACT "$Components_Navigation_NavigationBar_AdditionalItems" "Navigation/NavigationBar/AdditionalItems.tsx"
    REMOVE_REACT "$Components_Navigation_NavigationBar_AfterNavigation" "Navigation/NavigationBar/AfterNavigation.tsx"
    REMOVE_REACT "$Components_Navigation_SubNavigation_BeforeSubNavigation" "Navigation/SubNavigation/BeforeSubNavigation.tsx"
    REMOVE_REACT "$Components_Navigation_SubNavigation_AdditionalServerItems" "Navigation/SubNavigation/AdditionalServerItems.tsx"
    REMOVE_REACT "$Components_Navigation_SubNavigation_AdditionalAccountItems" "Navigation/SubNavigation/AdditionalAccountItems.tsx"
    REMOVE_REACT "$Components_Navigation_SubNavigation_AfterSubNavigation" "Navigation/SubNavigation/AfterSubNavigation.tsx"

    # dashboard
    REMOVE_REACT "$Components_Dashboard_ServerRow_BeforeEntryName" "Dashboard/ServerRow/BeforeEntryName.tsx"
    REMOVE_REACT "$Components_Dashboard_ServerRow_AfterEntryName" "Dashboard/ServerRow/AfterEntryName.tsx"
    REMOVE_REACT "$Components_Dashboard_ServerRow_BeforeEntryDescription" "Dashboard/ServerRow/BeforeEntryDescription.tsx"
    REMOVE_REACT "$Components_Dashboard_ServerRow_AfterEntryDescription" "Dashboard/ServerRow/AfterEntryDescription.tsx"
    REMOVE_REACT "$Components_Dashboard_ServerRow_ResourceLimits" "Dashboard/ServerRow/ResourceLimits.tsx"

    # authentication
    REMOVE_REACT "$Components_Authentication_Container_BeforeContent" "Authentication/Container/BeforeContent.tsx"
    REMOVE_REACT "$Components_Authentication_Container_AfterContent" "Authentication/Container/AfterContent.tsx"

    # server
    REMOVE_REACT "$Components_Server_Terminal_BeforeContent" "Server/Terminal/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Terminal_AfterContent" "Server/Terminal/AfterContent.tsx"

    REMOVE_REACT "$Components_Server_Files_Browse_BeforeContent" "Server/Files/Browse/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Files_Browse_FileButtons" "Server/Files/Browse/FileButtons.tsx"
    REMOVE_REACT "$Components_Server_Files_Browse_DropdownItems" "Server/Files/Browse/DropdownItems.tsx"
    REMOVE_REACT "$Components_Server_Files_Browse_AfterContent" "Server/Files/Browse/AfterContent.tsx"
    REMOVE_REACT "$Components_Server_Files_Edit_BeforeEdit" "Server/Files/Edit/BeforeEdit.tsx"
    REMOVE_REACT "$Components_Server_Files_Edit_AfterEdit" "Server/Files/Edit/AfterEdit.tsx"
    
    REMOVE_REACT "$Components_Server_Databases_BeforeContent" "Server/Databases/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Databases_AfterContent" "Server/Databases/AfterContent.tsx"

    REMOVE_REACT "$Components_Server_Schedules_List_BeforeContent" "Server/Schedules/List/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Schedules_List_AfterContent" "Server/Schedules/List/AfterContent.tsx"
    REMOVE_REACT "$Components_Server_Schedules_Edit_BeforeEdit" "Server/Schedules/Edit/BeforeEdit.tsx"
    REMOVE_REACT "$Components_Server_Schedules_Edit_AfterEdit" "Server/Schedules/Edit/AfterEdit.tsx"

    REMOVE_REACT "$Components_Server_Users_BeforeContent" "Server/Users/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Users_AfterContent" "Server/Users/AfterContent.tsx"

    REMOVE_REACT "$Components_Server_Backups_BeforeContent" "Server/Backups/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Backups_DropdownItems" "Server/Backups/DropdownItems.tsx"
    REMOVE_REACT "$Components_Server_Backups_AfterContent" "Server/Backups/AfterContent.tsx"

    REMOVE_REACT "$Components_Server_Network_BeforeContent" "Server/Network/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Network_AfterContent" "Server/Network/AfterContent.tsx"

    REMOVE_REACT "$Components_Server_Startup_BeforeContent" "Server/Startup/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Startup_AfterContent" "Server/Startup/AfterContent.tsx"

    REMOVE_REACT "$Components_Server_Settings_BeforeContent" "Server/Settings/BeforeContent.tsx"
    REMOVE_REACT "$Components_Server_Settings_AfterContent" "Server/Settings/AfterContent.tsx"

    # account
    REMOVE_REACT "$Components_Account_Overview_BeforeContent" "Account/Overview/BeforeContent.tsx"
    REMOVE_REACT "$Components_Account_Overview_AfterContent" "Account/Overview/AfterContent.tsx"

    REMOVE_REACT "$Components_Account_API_BeforeContent" "Account/API/BeforeContent.tsx"
    REMOVE_REACT "$Components_Account_API_AfterContent" "Account/API/AfterContent.tsx"

    REMOVE_REACT "$Components_Account_SSH_BeforeContent" "Account/SSH/BeforeContent.tsx"
    REMOVE_REACT "$Components_Account_SSH_AfterContent" "Account/SSH/AfterContent.tsx"

    rm -r $FOLDER/.blueprint/extensions/"$identifier"/components
    rm -r $FOLDER/resources/scripts/blueprint/extensions/"$identifier"
    YARN="y"
  fi

  # Remove custom routes
  PRINT INFO "Unlinking navigation routes.."
  sed -i \
    -e "s/\/\* ${identifier^}ImportStart \*\/.*\/\* ${identifier^}ImportEnd \*\///" \
    -e "s~/\* ${identifier^}ImportStart \*/~~g" \
    -e "s~/\* ${identifier^}ImportEnd \*/~~g" \
    \
    -e "s/\/\* ${identifier^}AccountRouteStart \*\/.*\/\* ${identifier^}AccountRouteEnd \*\///" \
    -e "s~/\* ${identifier^}AccountRouteStart \*~~g" \
    -e "s~/\* ${identifier^}AccountRouteEnd \*~~g" \
    \
    -e "s/\/\* ${identifier^}ServerRouteStart \*\/.*\/\* ${identifier^}ServerRouteEnd \*\///" \
    -e "s~/\* ${identifier^}ServerRouteStart \*~~g" \
    -e "s~/\* ${identifier^}ServerRouteEnd \*~~g" \
    \
    "resources/scripts/blueprint/extends/routers/routes.ts"

  # Remove private folder
  PRINT INFO "Removing and unlinking private folder.."
  rm -R ".blueprint/extensions/$identifier/private"

  # Remove public folder
  if [[ $data_public != "" ]]; then 
    PRINT INFO "Removing and unlinking public folder.."
    rm -R \
      ".blueprint/extensions/$identifier/public" \
      "public/extensions/$identifier"
  fi  

  # Remove assets folder
  PRINT INFO "Removing and unlinking assets folder.."
  rm -R \
    ".blueprint/extensions/$identifier/assets" \
    "public/assets/extensions/$identifier"

  # Remove extension directory
  PRINT INFO "Removing extension folder.."
  rm -R ".blueprint/extensions/$identifier"

  # Rebuild panel
  if [[ $YARN == "y" ]]; then
    PRINT INFO "Rebuilding panel assets.."
    yarn run build:production
  fi

  # Flush cache.
  PRINT INFO "Flushing view, config and route cache.."
  {
    php artisan view:clear
    php artisan config:clear
    php artisan route:cache
    php artisan cache:clear
  } &>> $BLUEPRINT__DEBUG 
  
  # Remove from installed list
  PRINT INFO "Removing '$identifier' from active extensions list.."
  sed -i "s~$identifier,~~g" ".blueprint/extensions/blueprint/private/db/installed_extensions"

  PRINT SUCCESS "'$identifier' has been removed."
  sendTelemetry "FINISH_EXTENSION_REMOVAL" >> $BLUEPRINT__DEBUG

  exit 0 # success
fi


# -v, -version
if [[ ( $2 == "-v" ) || ( $2 == "-version" ) ]]; then VCMD="y"
  echo -e ${VERSION}
fi


# -debug
if [[ $2 == "-debug" ]]; then VCMD="y"
  if [[ $3 -lt 1 ]]; then PRINT FATAL "Provide the amount of debug lines to print as an argument, which must be greater than one (1)."; exit 2; fi
  echo -e "\x1b[30;47;1m  --- DEBUG START ---  \x1b[0m"
  echo -e "$(v="$(<.blueprint/extensions/blueprint/private/debug/logs.txt)";printf -- "%s" "$v"|tail -"$3")"
  echo -e "\x1b[30;47;1m  ---  DEBUG END  ---  \x1b[0m"
fi


# -init
if [[ ( $2 == "-init" || $2 == "-I" ) ]]; then VCMD="y"
  # Check for developer mode through the database library.
  if ! dbValidate "blueprint.developerEnabled"; then PRINT FATAL "Developer mode is not enabled.";exit 2; fi

  # To prevent accidental wiping of your dev directory, you are unable to initialize another extension
  # until you wipe the contents of the .blueprint/dev directory.
  if [[ -n $(find .blueprint/dev -maxdepth 1 -type f -not -name ".gitkeep" -print -quit) ]]; then
    PRINT FATAL "Development directory contains files. To protect you against accidental data loss, you are unable to initialize another extension unless you clear the '.blueprint/dev' folder."
    exit 2
  fi

  ask_template() {
    PRINT INPUT "Choose an extension template:"
    echo -e "$(curl 'https://raw.githubusercontent.com/teamblueprint/templates/main/repository' 2>> $BLUEPRINT__DEBUG)"
    read -r ASKTEMPLATE
    REDO_TEMPLATE=false

    # Template should not be empty
    if [[ ${ASKTEMPLATE} == "" ]]; then 
      PRINT WARNING "Template should not be empty."
      REDO_TEMPLATE=true
    fi
    # Unknown template.
    if [[ $(echo -e "$(curl "https://raw.githubusercontent.com/teamblueprint/templates/main/${ASKTEMPLATE}/TemplateConfiguration.yml" 2>> $BLUEPRINT__DEBUG)") == "404: Not Found" ]]; then 
      PRINT WARNING "Unknown template, please choose a valid option."
      REDO_TEMPLATE=true
    fi

    # Ask again if response does not pass validation.
    if [[ ${REDO_TEMPLATE} == true ]]; then ASKTEMPLATE=""; ask_template; fi
  }

  ask_name() {
    PRINT INPUT "Name [SpaceInvaders]:"
    read -r ASKNAME
    REDO_NAME=false

    # Name should not be empty
    if [[ ${ASKNAME} == "" ]]; then 
      PRINT WARNING "Name should not be empty."
      REDO_NAME=true
    fi

    # Ask again if response does not pass validation.
    if [[ ${REDO_NAME} == true ]]; then ASKNAME=""; ask_name; fi
  }

  ask_identifier() {
    PRINT INPUT "Identifier [spaceinvaders]:"
    read -r ASKIDENTIFIER
    REDO_IDENTIFIER=false

    # Identifier should not be empty
    if [[ ${ASKIDENTIFIER} == "" ]]; then
      PRINT WARNING "Identifier should not be empty."
      REDO_IDENTIFIER=true
    fi
    # Identifier should be a-z.
    if ! [[ ${ASKIDENTIFIER} =~ [a-z] ]]; then
      PRINT WARNING "Identifier should only contain a-z characters."
      REDO_IDENTIFIER=true
    fi

    # Ask again if response does not pass validation.
    if [[ ${REDO_IDENTIFIER} == true ]]; then ASKIDENTIFIER=""; ask_identifier; fi
  }

  ask_description() {
    PRINT INPUT "Description [Shoot down space aliens!]:"
    read -r ASKDESCRIPTION
    REDO_DESCRIPTION=false

    # Description should not be empty
    if [[ ${ASKDESCRIPTION} == "" ]]; then
      PRINT WARNING "Description should not be empty."
      REDO_DESCRIPTION=true
    fi
    
    # Ask again if response does not pass validation.
    if [[ ${REDO_DESCRIPTION} == true ]]; then ASKDESCRIPTION=""; ask_description; fi
  }

  ask_version() {
    PRINT INPUT "Version [1.0]:"
    read -r ASKVERSION
    REDO_VERSION=false

    # Version should not be empty
    if [[ ${ASKVERSION} == "" ]]; then
      PRINT WARNING "Version should not be empty."
      REDO_VERSION=true
    fi

    # Ask again if response does not pass validation.
    if [[ ${REDO_VERSION} == true ]]; then ASKVERSION=""; ask_version; fi
  }

  ask_author() {
    PRINT INPUT "Author [byte]:"
    read -r ASKAUTHOR
    REDO_AUTHOR=false

    # Author should not be empty
    if [[ ${ASKAUTHOR} == "" ]]; then
      PRINT WARNING "Author should not be empty."
      REDO_AUTHOR=true
    fi
    
    # Ask again if response does not pass validation.
    if [[ ${REDO_AUTHOR} == true ]]; then ASKAUTHOR=""; ask_author; fi
  }

  ask_template
  ask_name
  ask_identifier
  ask_description
  ask_version
  ask_author

  tnum=${ASKTEMPLATE}
  PRINT INFO "Fetching templates.."
  if [[ $(php artisan bp:latest) != "$VERSION" ]]; then PRINT WARNING "Installed Blueprint version is not latest, you might run into compatibility issues."; fi
  cd .blueprint/tmp || cdhalt
  git clone "https://github.com/teamblueprint/templates.git"
  cd ${FOLDER}/.blueprint || cdhalt
  cp -R tmp/templates/* extensions/blueprint/private/build/templates/
  rm -R tmp/templates
  cd ${FOLDER} || cdhalt

  eval "$(parse_yaml .blueprint/extensions/blueprint/private/build/templates/"${tnum}"/TemplateConfiguration.yml t_)"

  PRINT INFO "Building template.."
  mkdir -p .blueprint/tmp/init
  cp -R .blueprint/extensions/blueprint/private/build/templates/"${tnum}"/contents/* .blueprint/tmp/init/

  sed -i \
    -e "s~␀name␀~${ASKNAME}~g" \
    -e "s~␀identifier␀~${ASKIDENTIFIER}~g" \
    -e "s~␀description␀~${ASKDESCRIPTION}~g" \
    -e "s~␀ver␀~${ASKVERSION}~g" \
    -e "s~␀author␀~${ASKAUTHOR}~g" \
    -e "s~␀version␀~${VERSION}~g" \
    -e "s~\[name\]~${ASKNAME}~g" \
    -e "s~\[identifier\]~${ASKIDENTIFIER}~g" \
    -e "s~\[description\]~${ASKDESCRIPTION}~g" \
    -e "s~\[ver\]~${ASKVERSION}~g" \
    -e "s~\[author\]~${ASKAUTHOR}~g" \
    -e "s~\[version\]~${VERSION}~g" \
    ".blueprint/tmp/init/conf.yml"

  # Return files to folder.
  cp -R .blueprint/tmp/init/* .blueprint/dev/

  # Remove tmp files.
  PRINT INFO "Cleaning up build files.."
  rm -R \
    ".blueprint/tmp" \
    ".blueprint/extensions/blueprint/private/build/templates/"*
  mkdir -p .blueprint/tmp

  sendTelemetry "INITIALIZE_DEVELOPMENT_EXTENSION" >> $BLUEPRINT__DEBUG

  PRINT SUCCESS "Extension files initialized and imported to '.blueprint/dev'."
fi


# -build
if [[ ( $2 == "-build" || $2 == "-b" ) ]]; then VCMD="y"
  # Check for developer mode through the database library.
  if ! dbValidate "blueprint.developerEnabled"; then PRINT FATAL "Developer mode is not enabled.";exit 2; fi

  if [[ -z $(find .blueprint/dev -maxdepth 1 -type f -not -name ".gitkeep" -print -quit) ]]; then
    PRINT FATAL "Development directory is empty."
    exit 2
  fi
  PRINT INFO "Starting developer extension installation.."
  blueprint -i "[developer-build]"
fi


# -export
if [[ ( $2 == "-export" || $2 == "-e" ) ]]; then VCMD="y"
  # Check for developer mode through the database library.
  if ! dbValidate "blueprint.developerEnabled"; then PRINT FATAL "Developer mode is not enabled.";exit 2; fi

  if [[ -z $(find .blueprint/dev -maxdepth 1 -type f -not -name ".gitkeep" -print -quit) ]]; then
    PRINT FATAL "Development directory is empty."
    exit 2
  fi

  PRINT INFO "Start packaging extension.."

  cd .blueprint || cdhalt
  rm dev/.gitkeep 2>> $BLUEPRINT__DEBUG

  eval "$(parse_yaml dev/conf.yml conf_)"; identifier="${conf_info_identifier}"

  cp -r dev/* tmp/
  cd tmp || cdhalt

  # Assign variables to extension flags.
  flags="$conf_info_flags"
  PRINT INFO "Reading and assigning extension flags.."
  assignflags

  if $F_hasExportScript; then
    chmod +x "${conf_data_directory}""/export.sh"

    # Run script while also parsing some useful variables for the export script to use.
    EXTENSION_IDENTIFIER="$conf_info_identifier"        \
    EXTENSION_TARGET="$conf_info_target"                \
    EXTENSION_VERSION="$conf_info_version"              \
    PTERODACTYL_DIRECTORY="$FOLDER"                     \
    BLUEPRINT_EXPORT_DIRECTORY="$FOLDER/.blueprint/tmp" \
    BLUEPRINT_VERSION="$VERSION"                        \
    bash "${conf_data_directory}""/export.sh"

    echo -e "\e[0m\x1b[0m\033[0m"
  fi

  zip -r extension.zip ./*
  cd ${FOLDER} || cdhalt
  cp .blueprint/tmp/extension.zip "${identifier}.blueprint"
  rm -R .blueprint/tmp
  mkdir -p .blueprint/tmp

  if [[ $3 == "expose"* ]]; then 
    PRINT INFO "Generating download url.. (expires after 2 minutes)"
    randstr=${RANDOM}${RANDOM}${RANDOM}${RANDOM}${RANDOM}
    mkdir .blueprint/extensions/blueprint/assets/exports/${randstr}
    cp "${identifier}".blueprint .blueprint/extensions/blueprint/assets/exports/${randstr}/"${identifier}".blueprint

    sendTelemetry "EXPOSE_DEVELOPMENT_EXTENSION" >> $BLUEPRINT__DEBUG
    PRINT SUCCESS "Extension has been exported to '$(grabAppUrl)/assets/extensions/blueprint/exports/${randstr}/${identifier}.blueprint' and '${FOLDER}/${identifier}.blueprint'."

    eval "$(sleep 120 && rm -R .blueprint/extensions/blueprint/assets/exports/${randstr} 2>> $BLUEPRINT__DEBUG)" &
  else
    sendTelemetry "EXPORT_DEVELOPMENT_EXTENSION" >> $BLUEPRINT__DEBUG
    PRINT SUCCESS "Extension has been exported to '${FOLDER}/${identifier}.blueprint'."
  fi
fi


# -wipe
if [[ ( $2 == "-wipe" || $2 == "-w" ) ]]; then VCMD="y"
  # Check for developer mode through the database library.
  if ! dbValidate "blueprint.developerEnabled"; then PRINT FATAL "Developer mode is not enabled.";exit 2; fi

  if [[ -z $(find .blueprint/dev -maxdepth 1 -type f -not -name ".gitkeep" -print -quit) ]]; then
    PRINT FATAL "Development directory is empty."
    exit 2
  fi

  PRINT INPUT "You are about to wipe all of your development files, are you sure you want to continue? This cannot be undone. (y/N)"
  read -r YN
  if [[ ( ( ${YN} != "y"* ) && ( ${YN} != "Y"* ) ) || ( ( ${YN} == "" ) ) ]]; then PRINT INFO "Development files removal cancelled.";exit 1;fi

  PRINT INFO "Clearing development folder.."
  rm -R \
    .blueprint/dev/* \
    .blueprint/dev/.* \
    2>> $BLUEPRINT__DEBUG

  PRINT SUCCESS "Development folder has been cleared."
fi


# -info
if [[ ( $2 == "-info" || $2 == "-f" ) ]]; then VCMD="y"
  fetchversion()    { printf "\x1b[0m\x1b[37m"; if [[ $VERSION != "" ]]; then echo $VERSION; else echo "none"; fi }
  fetchfolder()     { printf "\x1b[0m\x1b[37m"; if [[ $FOLDER != "" ]]; then echo $FOLDER; else echo "none"; fi }
  fetchurl()        { printf "\x1b[0m\x1b[37m"; if [[ $(grabAppUrl) != "" ]]; then grabAppUrl; else echo "none"; fi }
  fetchlocale()     { printf "\x1b[0m\x1b[37m"; if [[ $(grabAppLocale) != "" ]]; then grabAppLocale; else echo "none"; fi }
  fetchtimezone()   { printf "\x1b[0m\x1b[37m"; if [[ $(grabAppTimezone) != "" ]]; then grabAppTimezone; else echo "none"; fi }
  fetchextensions() { printf "\x1b[0m\x1b[37m"; tr -cd ',' <.blueprint/extensions/blueprint/private/db/installed_extensions | wc -c | tr -d ' '; }
  fetchdeveloper()  { printf "\x1b[0m\x1b[37m"; if dbValidate "blueprint.developerEnabled"; then echo "true"; else echo "false"; fi; }
  fetchtelemetry()  { printf "\x1b[0m\x1b[37m"; if [[ $(cat .blueprint/extensions/blueprint/private/db/telemetry_id) == "KEY_NOT_UPDATED" ]]; then echo "false"; else echo "true"; fi; }
  fetchnode()       { printf "\x1b[0m\x1b[37m"; if [[ $(node -v) != "" ]]; then node -v; else echo "none"; fi }
  fetchyarn()       { printf "\x1b[0m\x1b[37m"; if [[ $(yarn -v) != "" ]]; then yarn -v; else echo "none"; fi }

  echo    " "
  echo -e "\x1b[34;1m    ⣿⣿    Version: $(fetchversion)"
  echo -e "\x1b[34;1m  ⣿⣿  ⣿⣿  Folder: $(fetchfolder)"
  echo -e "\x1b[34;1m    ⣿⣿⣿⣿  URL: $(fetchurl)"
  echo -e "\x1b[34;1m          Locale: $(fetchlocale)"
  echo -e "\x1b[34;1m          Timezone: $(fetchtimezone)"
  echo -e "\x1b[34;1m          Extensions: $(fetchextensions)"
  echo -e "\x1b[34;1m          Developer: $(fetchdeveloper)"
  echo -e "\x1b[34;1m          Telemetry: $(fetchtelemetry)"
  echo -e "\x1b[34;1m          Node: $(fetchnode)"
  echo -e "\x1b[34;1m          Yarn: $(fetchyarn)"
  echo -e "\x1b[0m"
fi


# -rerun-install
if [[ $2 == "-rerun-install" ]]; then VCMD="y"
  PRINT WARNING "This is an advanced feature, only proceed if you know what you are doing."
  dbRemove "blueprint.setupFinished"
  cd ${FOLDER} || cdhalt
  bash blueprint.sh
fi


# -upgrade
if [[ $2 == "-upgrade" ]]; then VCMD="y"
  PRINT WARNING "This is an advanced feature, only proceed if you know what you are doing."

  if [[ -n $(find .blueprint/dev -maxdepth 1 -type f -not -name ".gitkeep" -print -quit) ]]; then
    PRINT FATAL "Development directory contains files. To protect you against accidental data loss, you are unable to upgrade unless you clear the '.blueprint/dev' folder."
    exit 2
  fi


  # Confirmation question for developer upgrade.
  if [[ $3 == "dev" ]]; then
    PRINT INPUT "Upgrading to the latest development build will update Blueprint to an unstable work-in-progress preview of the next version. Continue? (y/N)"
    read -r YN
    if [[ ( ${YN} != "y"* ) && ( ${YN} != "Y"* ) ]]; then PRINT INFO "Upgrade cancelled.";exit 1;fi
    YN=""
  fi

  # Confirmation question for both developer and stable upgrade.
  PRINT INPUT "Upgrading will wipe your .blueprint folder and will deactivate all active extensions. Continue? (y/N)"
  read -r YN
  if [[ ( ${YN} != "y"* ) && ( ${YN} != "Y"* ) ]]; then PRINT INFO "Upgrade cancelled.";exit 1;fi
  YN=""

  # Last confirmation question for both developer and stable upgrade.
  PRINT INPUT "This is the last warning before upgrading/wiping Blueprint. Type 'continue' to continue, all other input will be taken as 'no'."
  read -r YN
  if [[ ${YN} != "continue" ]]; then PRINT INFO "Upgrade cancelled.";exit 1;fi
  YN=""


  if [[ $3 == "dev" ]]; then PRINT INFO "Fetching and pulling latest commit.."
  else                       PRINT INFO "Fetching and pulling latest release.."; fi

  cp blueprint.sh .blueprint.sh.bak

  mkdir $FOLDER/.tmp
  cd $FOLDER/.tmp || cdhalt
  if [[ $3 == "dev" ]]; then
    # download latest commit
    git clone https://github.com/teamblueprint/main.git
  else
    # download latest release
    LOCATION=$(curl -s https://api.github.com/repos/teamblueprint/main/releases/latest \
  | grep "zipball_url" \
  | awk '{ print $2 }' \
  | sed 's/,$//'       \
  | sed 's/"//g' )     \
  ; curl -L -o main.zip "$LOCATION"

    unzip main.zip
    rm main.zip
    mv ./* main
  fi

  cp -r main/* "$FOLDER"/
  rm -r  \
    "main" \
    "$FOLDER"/.blueprint \
    "$FOLDER"/.tmp
  cd $FOLDER || cdhalt

  chmod +x blueprint.sh
  sed -i -E "s|FOLDER=\"/var/www/pterodactyl\" #;|FOLDER=\"$FOLDER\" #;|g" $FOLDER/blueprint.sh
  mv $FOLDER/blueprint $FOLDER/.blueprint;
  bash blueprint.sh --post-upgrade

  # Ask user if they'd like to migrate their database.
  PRINT INPUT "Would you like to migrate your database? (Y/n)"
  read -r YN
  if [[ ( $YN == "y"* ) || ( $YN == "Y"* ) || ( $YN == "" ) ]]; then 
    PRINT INFO "Running database migrations.."
    php artisan migrate --force
  else
    PRINT INFO "Database migrations have been skipped."
  fi
  YN=""

  # Post-upgrade checks.
  PRINT INFO "Validating update.."
  score=0

  if dbValidate "blueprint.setupFinished"; then score=$((score+1))
  else PRINT WARNING "'blueprint.setupFinished' could not be detected or found."; fi

  # Finalize upgrade.
  if [[ ${score} == 1 ]]; then
    PRINT SUCCESS "Upgrade finished."
    rm .blueprint.sh.bak
    exit 0 # success
  elif [[ ${score} == 0 ]]; then
    PRINT FATAL "All checks have failed. The 'blueprint.sh' file has been reverted."
    rm blueprint.sh
    mv .blueprint.sh.bak blueprint.sh
    exit 1 # error
  else
    PRINT FATAL "Some checks have failed. The 'blueprint.sh' file has been reverted."
    rm blueprint.sh
    mv .blueprint.sh.bak blueprint.sh
    exit 1 # error
  fi
fi



# When the users attempts to run an invalid command.
if [[ ${VCMD} != "y" && $1 == "-bash" ]]; then
  # This is logged as a "fatal" error since it's something that is making Blueprint run unsuccessfully.
  PRINT FATAL "'$2' is not a valid command or argument. Use argument '-help' for a list of commands."
  exit 1
fi
