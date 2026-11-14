# FleetDeck Agent — Windows installer

Signed installer for the **FleetDeck Agent** service (the Fleet device agent,
rebranded). Intended use: out-of-band installation of the agent on Windows
endpoints that are managed by your FleetDeck server.

| | |
|---|---|
| File | `FleetDeck-Agent-Setup.exe` |
| Size | 4,391,192 bytes |
| SHA-256 | `DAAA8956CCB04D8F50AEC2BB0CD39155E1BA223779588E785BA6931B154E0F4F` |
| MD5 | `E71BC3644804B3221CD3326E8CBEDFC6` |
| Signer | `CN=Fleetdeck Inc., O=Fleetdeck Inc., L=Hermosa Beach, S=California, C=US` |
| Issuer | `SSL.com Code Signing Intermediate CA ECC R2` |
| Type | 32-bit PE, Windows GUI, Go-built WiX MSI installer |

The installer drops a signed MSI that installs the agent service
(`fleetdeck_agent_svc.exe`, SHA-256
`BD0285B480122F05AE85BAE5EDFFA751095DDD216D05C04DAFB204950B17C863`) running as
`LocalSystem`, with start type `restart`, plus a full uninstall path.

## Verifying the download before you run it

```powershell
Get-FileHash -Path .\FleetDeck-Agent-Setup.exe -Algorithm SHA256
# expect: DAAA8956CCB04D8F50AEC2BB0CD39155E1BA223779588E785BA6931B154E0F4F

Get-AuthenticodeSignature -Path .\FleetDeck-Agent-Setup.exe | Format-List Status,SignerCertificate
# expect: Status = Valid, subject CN=Fleetdeck Inc.
```

Both files are signed end to end. Nothing in this package is obfuscated or
packed — if a byte differs from the hash above, stop.

## Automatic download

`get-installer.ps1` downloads the installer and verifies its SHA-256 before
saving it. It never runs the installer.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File get-installer.ps1
```

## "My antivirus is blocking this"

This is a known problem with MDM agent installers, and it is not a sign of a
malicious file. The usual triggers, in order of impact:

1. **The file name does not match the product.** Reputation engines correlate
   the file name with the product name and with the signer. Download it as
   `FleetDeck-Agent-Setup.exe`, not under a shortened or unrelated name.
2. **The agent binary is installed under a randomised name** (for example
   `j6y-ax3v.exe`) in a randomised folder. That defeats filename-based
   reputation. Either keep the canonical name
   (`fleetdeck_agent_svc.exe`) and path, or enrol the resulting hashes with
   the vendors.
3. **The certificate is new.** A recently issued code-signing certificate has
   no reputation yet. An **EV** code-signing certificate is trusted
   immediately by Norton, McAfee and ESET, because the CA has verified the
   publisher's legal identity.
4. **The installer writes to system directories and creates a service.**
   Expect a SmartScreen or "unrecognised publisher" prompt on first run from
   a browser-downloaded file. Distribute the file through a channel that
   preserves its hash (a release asset, not a re-zipped copy), or let the MDM
   server deliver it.

### Whitelisting

Submit a false-positive report to each vendor with the details in the table
above. Each has a public form and expects the same evidence:

- McAfee / Norton (Symantec / Broadcom) — `https://submit.avportal.com/`
  and `https://submit.symantec.com/false_positive/`
- ESET — `https://www.eset.com/int/about/support/contact/`
- Sophos — `https://www.sophos.com/en-us/support`
- Microsoft Defender — `https://www.microsoft.com/en-us/wdsi/filesubmission`
  and `https://www.microsoft.com/en-us/wdsi/submission`

Upload the *signed* file, not a renamed or repacked copy, and keep publishing
the same bytes so the reputation applies to the hash your endpoints fetch.

## What this agent does

It installs and maintains the FleetDeck device agent service, self-updates from
`https://agentupdate.fleetdeck.io`, manages its own firewall rule, and reports
device state to your FleetDeck server. It has no mail-sending capability and no
relationship to any mail campaign.

## Install

```
FleetDeck-Agent-Setup.exe /install
```

Silent uninstall:

```
msiexec /x {C85749BC-9450-4BCE-89D1-F6C37A8588B2}
```

The installer also accepts the standard WiX properties (`/qn`, `TARGETDIR=`,
`ASSIGNED=`), and the MSI can be handed to the FleetDeck server directly if you
would rather deploy it through the management channel than download it.

## Licence

Published by Mowafak Store on behalf of Fleetdeck Inc. The FleetDeck name and
the signing certificate belong to their respective owners.
