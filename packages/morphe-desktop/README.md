

# deps.json
$(nix build '.#morphe-desktop.mitmCache.updateScript' --print-out-paths)



# obsolete
- authenticate to https://github.com/settings/tokens
- generate a classic token with permissions read:packages
- create/update ~/.gradle/gradle.properties :
  gpr.user=USERNAME
  gpr.key=ghp_TOKEN
- put generateDeps.gradle inside the source
- run
  ./gradlew --init-script generateDeps.gradle generateDepsJson --warning-mode all
