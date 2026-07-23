#!/usr/bin/env python3
"""Generate a signed custom.txt for the UCSN custom-client config feature.

Reads the signing seed and preset values from environment variables (set as
GitHub Actions secrets in CI, never committed to the repo) and writes a
base64 signature+payload blob that src/common.rs::read_custom_client()
verifies against the public key compiled into the app.

Requires: pip install pynacl
"""
import base64
import json
import os
import sys

import nacl.signing


def main() -> None:
    if len(sys.argv) != 2:
        print("usage: generate_custom_txt.py <output-path>", file=sys.stderr)
        sys.exit(1)

    seed_b64 = os.environ["UCSN_CUSTOM_CLIENT_SEED"]
    payload = {}
    if password := os.environ.get("UCSN_PRESET_PASSWORD"):
        payload["password"] = password
    if pin := os.environ.get("UCSN_UNLOCK_PIN"):
        payload["unlock-pin"] = pin

    signing_key = nacl.signing.SigningKey(base64.b64decode(seed_b64))
    message = json.dumps(payload).encode()
    signed = signing_key.sign(message)  # 64-byte signature + message
    out = base64.b64encode(bytes(signed)).decode()

    with open(sys.argv[1], "w") as f:
        f.write(out)


if __name__ == "__main__":
    main()
