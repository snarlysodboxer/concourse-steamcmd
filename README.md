# SteamCMD Concourse Resource

A [Concourse CI](https://concourse-ci.org/) resource for detecting new versions of Steam games using SteamCMD.

This resource monitors Steam applications for version changes by querying their build IDs through SteamCMD, making it perfect for triggering CI/CD pipelines when games receive updates.

## Resource Type Configuration

To use this resource, you first need to add it as a resource type to your pipeline:

```yaml
resource_types:
- name: steamcmd
  type: docker-image
  source:
    repository: your-registry/concourse-steamcmd
    tag: latest
```

## Source Configuration

- `app_id` **(required)**: The Steam application ID of the game to monitor
- `branch` _(optional, default: "public")_: The Steam branch to monitor (e.g., "public", "beta", "experimental")
- `username` _(optional)_: Steam username for accessing private applications
- `password` _(optional)_: Steam password for accessing private applications

## Behavior

### `check`: Check for new versions

Queries SteamCMD for the current build ID of the specified application and branch. Returns the new version if it differs from the last known version.

### `in`: Fetch version metadata

Downloads metadata about the detected version, including:

- Build ID
- Application ID
- Application name
- Branch name
- Timestamp
- Raw SteamCMD output (for debugging)

The following files are created in the resource directory:

- `buildid`: The Steam build ID
- `app_id`: The Steam application ID
- `app_name`: The human-readable application name
- `branch`: The Steam branch
- `timestamp`: Unix timestamp of when the check was performed
- `metadata.json`: All metadata in JSON format
- `steamcmd_output.txt`: Raw SteamCMD output for debugging

### `out`: Not supported

This resource does not support push operations as it's designed for monitoring only.

## Example Pipeline

Here's a complete example pipeline that triggers when Valheim receives an update:

```yaml
resource_types:
- name: steamcmd
  type: docker-image
  source:
    repository: your-registry/concourse-steamcmd
    tag: latest

resources:
# Monitor Valheim public branch
- name: valheim-version
  type: steamcmd
  source:
    app_id: "892970" # Valheim Steam App ID
    branch: "public"
  check_every: 10m

jobs:
# Job triggered when Valheim updates
- name: build-something
  plan:
  - get: valheim-version
    trigger: true
  - task: do-something
    config:
      platform: linux
      image_resource:
        type: docker-image
        source: { repository: ubuntu }
      inputs:
      - name: valheim-version
      run:
        path: bash
        args:
        - -c
        - |
          echo "=== New Valheim version detected! ==="
          echo "Build ID: $(cat valheim-version/buildid)"
          echo "App Name: $(cat valheim-version/app_name)"
          echo "Branch: $(cat valheim-version/branch)"
          echo "Timestamp: $(cat valheim-version/timestamp)"

          echo ""
          echo "=== Available metadata files ==="
          find valheim-version -type f | sort

          echo ""
          echo "=== Metadata JSON ==="
          cat valheim-version/metadata.json

          # Your build/deployment logic here
          # ...
```

## Finding Steam App IDs

To find the Steam App ID for a game:

1. Visit the game's Steam store page
2. Look at the URL: `https://store.steampowered.com/app/APPID/gamename/`
3. The number after `/app/` is the App ID

Common examples:

- **Satisfactory**: `526870`
- **Valheim**: `892970`
- **Rust**: `252490`
- **7 Days to Die**: `251570`
- **ARK: Survival Evolved**: `376030`

## Limitations

- Requires SteamCMD access to the application (public apps work without authentication)
- Private or restricted applications require valid Steam credentials
- Build ID comparison only - doesn't detect content changes within the same build
- Depends on Steam's availability and SteamCMD functionality

## Development

### Building the Docker Image

```bash
docker build -t concourse-steamcmd .
```

### Testing Locally

You can test the resource scripts locally (requires SteamCMD installation):

```bash
# Test check script
echo '{"source":{"app_id":"526870","branch":"public"}}' | ./assets/check

# Test in script
echo '{"source":{"app_id":"526870","branch":"public"},"version":{"buildid":"123456"}}' | ./assets/in /tmp/test-output
```

## Contributing

Contributions are welcome! Please ensure that:

1. Scripts remain POSIX-compliant where possible
2. Error handling is robust
3. Debug output is sent to stderr
4. JSON output follows Concourse resource conventions

## License

This project is open source. Please see the LICENSE file for details.
