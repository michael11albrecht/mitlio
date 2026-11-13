# mitlio

[![ci](https://github.com/michael11albrecht/mitlio/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/michael11albrecht/mitlio/actions/workflows/ci.yml?query=branch%3Amain)
[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

**The private taxometer.** Share car-ride costs and group expenses fairly — commutes, holidays, shared trips — with live fuel prices, simple settle-up via PayPal.Me or SEPA QR code, and no ads.

Status: early development. See [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md) for the full plan and [`docs/adr/`](docs/adr/) for decisions.

## Development

```sh
make bootstrap   # install dependencies and git hooks
make check       # full quality gate (definition of done)
make help        # all commands
```

Contributor and agent rules: [`CLAUDE.md`](CLAUDE.md).

## License

Copyright (C) 2026 Michael Albrecht

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3 or (at your option) any later version. See [`LICENSE`](LICENSE).
