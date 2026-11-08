# Dev scripts

- `xb.sh`: one xcodebuild (build or test) at a time under `/private/tmp/claude-501/wf-build.lock`, with a 45 minute watchdog. Needs `SIM`.
- `sim-reset.sh`: erase and boot a simulator between UI batches, with mediaanalysisd disabled inside it.
- `kill-mediaanalysis.sh`: keep a simulator's mediaanalysisd dead during a long UI run.

See `docs/pm/post-restart-runbook.md`.
