# Sound Assets

These are placeholder `.m4a` files. Replace them with real audio assets before shipping.

## Asset Requirements (Req 9.1, 9.2)
- Format: `.m4a` (AAC)
- Total bundle size: ≤ 2MB across ALL packs
- Duration: Short clips (< 3 seconds recommended)

## Cup-to-Sound Mapping (Req 10)

| Cup | Asset Name | Description | Tier |
|-----|-----------|-------------|------|
| 1 | `cup1_chime.m4a` | Soft chime | Free |
| 2 | `cup2_ding.m4a` | Approving ding | Free |
| 3 | `cup3_hmm.m4a` | Hmm voice | Free |
| 4 | `cup4_stethoscope.m4a` | Stethoscope concern | Pro |
| 5 | `cup5_ambulance.m4a` | Ambulance siren | Pro |
| 6+ | `cup6_siren.m4a` | Siren (chaos pool) | Pro |
| 6+ | `cup6_airhorn.m4a` | Air horn (chaos pool) | Pro |
| 6+ | `cup6_dialup.m4a` | Dial-up modem (chaos pool) | Pro |
| 6+ | `cup6_wilhelm.m4a` | Wilhelm scream (chaos pool) | Pro |

## Packs (Req 21)

Each subdirectory contains the same filenames but with pack-themed audio:
- `Default/` — Standard escalation sounds
- `YourMom/` — "Your Mom" themed pack
- `GordonRamsay/` — "Gordon Ramsay" themed pack
- `NASA/` — "NASA Mission Control" themed pack
- `Accountant/` — "The Accountant" themed pack

## Notes
- Sound copyright provenance (Req 53) is managed off-repo by the Launch Operator.
- Assets are lazy-loaded by SoundEngine on first play (Req 9.3).
