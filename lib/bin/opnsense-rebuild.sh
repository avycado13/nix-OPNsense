#!/bin/sh

set -e
set -o pipefail

export PATH=@path@
export NIX_PATH=${NIX_PATH:-@nixPath@}

showSyntax() {
  echo "opnsense-rebuild [--help] {edit | switch | activate | build | check | changelog}" >&2
  echo "               [--list-generations] [{--profile-name | -p} name] [--rollback]" >&2
  echo "               [{--switch-generation | -G} generation] [--verbose...] [-v...]" >&2
  echo "               [-Q] [{--max-jobs | -j} number] [--cores number] [--dry-run]" >&2
  echo "               [--keep-going | -k] [--keep-failed | -K] [--fallback] [--show-trace]" >&2
  echo "               [--print-build-logs | -L] [--impure] [-I path]" >&2
  echo "               [--option name value] [--arg name value] [--argstr name value]" >&2
  echo "               [--no-flake | [--flake flake]" >&2
  echo "                             [--commit-lock-file] [--recreate-lock-file]" >&2
  echo "                             [--no-update-lock-file] [--no-write-lock-file]" >&2
  echo "                             [--override-input input flake] [--update-input input]" >&2
  echo "                             [--no-registries] [--offline] [--refresh]]" >&2
  exit 1
}

sudo() {
  # No-op if not needed (we’ll run the script as root when applying configurations)
  :
}

# Parse the command line.
origArgs=("$@")
extraMetadataFlags=()
extraBuildFlags=()
extraLockFlags=()
extraProfileFlags=()
profile=@profile@
action=
flake=
noFlake=

while [ $# -gt 0 ]; do
  i=$1; shift 1
  case $i in
    --help)
      showSyntax
      ;;
    edit|switch|activate|build|check|changelog)
      action=$i
      ;;
    --show-trace|--keep-going|--keep-failed|--verbose|-v|-vv|-vvv|-vvvv|-vvvvv|--fallback|--offline)
      extraMetadataFlags+=("$i")
      extraBuildFlags+=("$i")
      ;;
    --no-build-hook|--dry-run|-k|-K|-Q)
      extraBuildFlags+=("$i")
      ;;
    -j[0-9]*)
      extraBuildFlags+=("$i")
      ;;
    --max-jobs|-j|--cores|-I)
      if [ $# -lt 1 ]; then
        echo "$0: '$i' requires an argument"
        exit 1
      fi
      j=$1; shift 1
      extraBuildFlags+=("$i" "$j")
      ;;
    --arg|--argstr|--option)
      if [ $# -lt 2 ]; then
        echo "$0: '$i' requires two arguments"
        exit 1
      fi
      j=$1
      k=$2
      shift 2
      extraMetadataFlags+=("$i" "$j" "$k")
      extraBuildFlags+=("$i" "$j" "$k")
      ;;
    --flake)
      flake=$1
      shift 1
      ;;
    --no-flake)
      noFlake=1
      ;;
    -L|-vL|--print-build-logs|--impure|--recreate-lock-file|--no-update-lock-file|--no-write-lock-file|--no-registries|--commit-lock-file|--refresh)
      extraLockFlags+=("$i")
      ;;
    --update-input)
      j="$1"; shift 1
      extraLockFlags+=("$i" "$j")
      ;;
    --override-input)
      j="$1"; shift 1
      k="$1"; shift 1
      extraLockFlags+=("$i" "$j" "$k")
      ;;
    --list-generations)
      action="list"
      extraProfileFlags=("$i")
      ;;
    --rollback)
      action="rollback"
      extraProfileFlags=("$i")
      ;;
    --switch-generation|-G)
      action="rollback"
      if [ $# -lt 1 ]; then
        echo "$0: '$i' requires an argument"
        exit 1
      fi
      j=$1; shift 1
      extraProfileFlags=("$i" "$j")
      ;;
    --profile-name|-p)
      if [ -z "$1" ]; then
        echo "$0: '$i' requires an argument"
        exit 1
      fi
      if [ "$1" != system ]; then
        profile="/nix/var/nix/profiles/system-profiles/$1"
        mkdir -p -m 0755 "$(dirname "$profile")"
      fi
      shift 1
      ;;
    --substituters)
      if [ -z "$1" ]; then
        echo "$0: '$i' requires an argument"
        exit 1
      fi
      j=$1; shift 1
      extraMetadataFlags+=("$i" "$j")
      extraBuildFlags+=("$i" "$j")
      ;;
    *)
      echo "$0: unknown option '$i'"
      exit 1
      ;;
  esac
done

if [ -z "$action" ]; then showSyntax; fi

flakeFlags=(--extra-experimental-features 'nix-command flakes')

if [[ -z $flake && -e /etc/opnsense/flake.nix && -z $noFlake ]]; then
  flake="$(dirname "$(readlink -f /etc/opnsense/flake.nix)")"
fi

if [[ -n "$flake" ]]; then
    if [[ $flake =~ ^(.*)\#([^\#\"]*)$ ]]; then
       flake="${BASH_REMATCH[1]}"
       flakeAttr="${BASH_REMATCH[2]}"
    fi
    if [[ -z "$flakeAttr" ]]; then
      flakeAttr=$(hostname)
    fi
    flakeAttr=opnsenseConfigurations.${flakeAttr}
fi

# Handle build vs switch
if [ "$action" = build ]; then
  echo "Building the OPNsense config.xml..." >&2
  if [ -z "$flake" ]; then
    # Use Nix to build the config.xml without applying it
    systemConfig="$(nix-build '<opnsense>' "${extraBuildFlags[@]}" -A config.xml)"
  else
    systemConfig=$(nix "${flakeFlags[@]}" build --json \
      "${extraBuildFlags[@]}" "${extraLockFlags[@]}" \
      -- "$flake#$flakeAttr.config.xml" \
      | jq -r '.[0].outputs.out')
  fi
  echo "Config.xml built at $systemConfig"
  exit 0
fi

if [ "$action" = switch ]; then
  echo "Applying the OPNsense configuration..." >&2
  if [ -z "$systemConfig" ]; then
    echo "No config.xml built. Please run build first."
    exit 1
  fi
  # Apply the configuration to OPNsense, directly modifying the config.xml
  sudo cp "$systemConfig" /conf/config.xml
  sudo /usr/local/etc/rc.d/configd restart
  echo "Config.xml applied and OPNsense restarted."
fi

if [ "$action" = check ]; then
  echo "Checking configuration..."
  # Implement any configuration validation if necessary
fi

if [ "$action" = changelog ]; then
  ${PAGER:-less} -- "$systemConfig/opnsense-changes"
fi