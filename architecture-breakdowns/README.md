# Architecture Breakdowns

Blueprints for orchestrating AI to build complex products layer-by-layer, following the methodology of [Chapter 23](../handbook/23-system-design-breakdowns.md): core domain first, architecture decisions stated before prompting, then a strict prompt *sequence* where each layer names its boundary and its review hook.

Each blueprint ends with a failure-mode bank (the extensions an interviewer will throw at you) and links to the interview playbooks and sample apps that exercise the same design.

| Blueprint | The hard problem | Key layers | Buildable reference |
| :--- | :--- | :--- | :--- |
| [Spotify](spotify.md) | App-lifetime playback state + offline-first storage | Audio engine actor · offline repository · global player state · mini player | [`music-interview-app`](../sample-apps/music-interview-app) (the Ch 9–16 spine), [`spotify-clone`](../sample-apps/spotify-clone) |
| [Instagram](instagram.md) | 120Hz scroll over infinite imagery + optimistic mutation | Image pipeline actor · cursor pagination state machine · optimistic likes · isolated cells | [`photo-feed` playbook](../interview-playbooks/architecture/photo-feed.md) |
| [Uber](uber.md) | Real-time bi-directional sync over an unreliable stream | WebSocket actor · snapshot+delta gap rule · trip state machine · interpolated map | [`uber-clone`](../sample-apps/uber-clone), [`live-sports-app` playbook](../interview-playbooks/architecture/live-sports-app.md) |

**How to use them:** don't copy the prompts blindly — the sequence *is* the lesson. Every blueprint prompts for the hardest dependency first (audio engine, image pipeline, transport) and the UI last, because a UI prompted first hardcodes assumptions the lower layers then have to satisfy.
