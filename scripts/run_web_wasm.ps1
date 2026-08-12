$ErrorActionPreference = 'Stop'

$port = if ($args.Count -gt 0) { $args[0] } else { '49543' }

flutter run `
  -d web-server `
  --wasm `
  --web-port $port `
  --web-hostname localhost
