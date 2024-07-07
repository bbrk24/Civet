#!/bin/bash
set -euo pipefail

# clean build
rm -rf dist
mkdir dist

# tree-shake needed constants from Vite
node -e 'import("./node_modules/vite/dist/node/constants.js").then((c)=>console.log(`export const DEFAULT_EXTENSIONS = ${JSON.stringify(c.DEFAULT_EXTENSIONS)}`))' >./source/unplugin/constants.ts

# types (these get used for type checking during esbuild, so must go first)
cp types/types.d.ts dist/types.d.ts

# normal files
civet --no-config build/esbuild.civet "$@"

# built types
for name in astro esbuild rollup unplugin vite webpack; do
  sed 's/\.civet"/\.js"/' dist/unplugin/unplugin/$name.civet.d.ts >dist/unplugin/$name.d.ts
done
rm -rf dist/unplugin/unplugin

# cli
BIN="dist/civet"
echo "#!/usr/bin/env node" | cat - dist/cli.js > "$BIN"
chmod +x "$BIN"
rm dist/cli.js

# babel plugin
cp source/babel-plugin.mjs dist/babel-plugin.mjs

# create browser build for docs
terser dist/browser.js --compress --mangle --ecma 2015 --output civet.dev/public/__civet.js

