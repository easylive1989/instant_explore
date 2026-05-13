"""Social-media publishing for the daily story.

`publisher.py` is the orchestrator (called from the 21:00 Asia/Taipei cron).
`threads.py` and `instagram.py` are thin REST clients for the respective
Meta Graph APIs. `caption.py` is the platform-agnostic copy builder.
"""
