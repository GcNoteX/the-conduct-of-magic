"""Writes the placeholder music loops in audio/placeholder_music/ (Claude-made stand-ins until real
music arrives).

Run from the project root:  python3 tools/placeholder_audio/make_placeholder_music.py
Needs numpy (pip install numpy) and ffmpeg with libvorbis on the PATH.

Each loop is synthesised from scratch with a fixed random seed, so a re-run gives the same files.
Notes that ring past the end of a loop are wrapped round to its start, so the loop is seamless.
- counter_theme.ogg: a light folk tune for the shop counter. Plucked lute, recorder melody, bass and
  a soft frame drum, in D major at 96 bpm, 16 bars.
- table_theme.ogg: a calm, glassy loop for the inscribing table. Slow pads, a low drone and sparse
  bells, in A minor at 66 bpm, 16 bars.
"""

import os
import subprocess
import tempfile
import wave

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "audio", "placeholder_music")
RATE = 44100
PEAK = 0.7  # final peak level, leaves headroom under the SFX


def midi_hz(note):
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def envelope(n, attack, release):
    """Linear attack, then a release over the last `release` seconds."""
    env = np.ones(n)
    a = min(int(attack * RATE), n)
    r = min(int(release * RATE), n - a)
    if a > 0:
        env[:a] = np.linspace(0.0, 1.0, a)
    if r > 0:
        env[n - r :] *= np.linspace(1.0, 0.0, r)
    return env


def pluck(freq, seconds, brightness=0.5, decay=0.996, rng=None):
    """Karplus-Strong plucked string, computed a period at a time."""
    period = max(int(RATE / freq), 2)
    n = int(seconds * RATE)
    out = np.zeros(n + period + 1)
    noise = rng.uniform(-1.0, 1.0, period)
    # Soften the excitation: a darker pluck has less high-frequency noise
    for _ in range(int((1.0 - brightness) * 6)):
        noise = 0.5 * (noise + np.roll(noise, 1))
    out[:period] = noise
    pos = period
    while pos < n + 1:
        end = min(pos + period, n + 1)
        prev = out[pos - period : end - period]
        prev_next = out[pos - period + 1 : end - period + 1]
        out[pos:end] = decay * 0.5 * (prev + prev_next)
        pos = end
    sig = out[:n]
    return sig * envelope(n, 0.002, 0.05)


def recorder(freq, seconds):
    """A breathy wind tone: sine plus soft harmonics, a gentle vibrato and a little breath noise."""
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    vib = 1.0 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.3, 0.0, 1.0)
    phase = 2 * np.pi * freq * np.cumsum(vib) / RATE
    tone = np.sin(phase) + 0.25 * np.sin(2 * phase) + 0.08 * np.sin(3 * phase)
    breath = np.random.default_rng(int(freq)).normal(0.0, 0.03, n)
    return (tone + breath) * envelope(n, 0.04, min(0.12, seconds * 0.4))


def pad(freq, seconds):
    """Three slightly detuned soft tones with slow swells."""
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    sig = np.zeros(n)
    for detune in (-0.12, 0.0, 0.12):
        f = freq * 2.0 ** (detune / 12.0)
        sig += np.sin(2 * np.pi * f * t) + 0.15 * np.sin(4 * np.pi * f * t)
    tremolo = 1.0 + 0.08 * np.sin(2 * np.pi * 0.25 * t)
    return sig / 3.0 * tremolo * envelope(n, 1.6, 1.8)


def bell(freq, seconds):
    """FM bell: an inharmonic modulator whose depth fades with the note."""
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    decay = np.exp(-t * 2.2)
    index = 2.5 * np.exp(-t * 3.0)
    sig = np.sin(2 * np.pi * freq * t + index * np.sin(2 * np.pi * freq * 3.5 * t))
    return sig * decay * envelope(n, 0.003, 0.2)


def frame_drum(seconds=0.6):
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    freq = 55.0 + 70.0 * np.exp(-t * 25.0)
    body = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * np.exp(-t * 7.0)
    slap = np.random.default_rng(7).normal(0.0, 1.0, n) * np.exp(-t * 60.0) * 0.15
    return body + slap


def shaker(seconds=0.09):
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    noise = np.random.default_rng(11).normal(0.0, 1.0, n)
    noise = noise - np.roll(noise, 1)  # brighter
    return noise * np.exp(-t * 45.0) * envelope(n, 0.01, 0.02)


class Track:
    """A mono mix bus the length of one loop, plus a tail that is wrapped to the start."""

    def __init__(self, bpm, bars, beats_per_bar=4, tail_seconds=4.0):
        self.beat = 60.0 / bpm
        self.length = int(round(bars * beats_per_bar * self.beat * RATE))
        self.buf = np.zeros(self.length + int(tail_seconds * RATE))

    def add(self, sig, at_beat, gain):
        start = int(round(at_beat * self.beat * RATE))
        end = min(start + len(sig), len(self.buf))
        self.buf[start:end] += sig[: end - start] * gain

    def render(self):
        loop = self.buf[: self.length].copy()
        tail = self.buf[self.length :]
        loop[: len(tail)] += tail
        loop -= loop.mean()
        return loop / np.max(np.abs(loop)) * PEAK


# --- Counter: D major, 96 bpm ------------------------------------------------------------------

D, E, Fs, G, A, B, Cs = 62, 64, 66, 67, 69, 71, 73
REST = None

COUNTER_CHORDS = [
    # (root, third, fifth) as MIDI notes around octave 3, one chord per bar
    (50, 54, 57),  # D
    (45, 49, 52),  # A
    (47, 50, 54),  # Bm
    (43, 47, 50),  # G
    (50, 54, 57),  # D
    (43, 47, 50),  # G
    (45, 49, 52),  # A
    (50, 54, 57),  # D
    (47, 50, 54),  # Bm
    (42, 45, 49),  # F#m
    (43, 47, 50),  # G
    (50, 54, 57),  # D
    (40, 43, 47),  # Em
    (45, 49, 52),  # A
    (43, 47, 50),  # G
    (50, 54, 57),  # D
]

# One list of (note, beats) per bar
COUNTER_MELODY = [
    [(Fs + 12, 1), (E + 12, 0.5), (D + 12, 0.5), (A, 1), (D + 12, 1)],
    [(Cs, 1.5), (B, 0.5), (A, 2)],
    [(B, 1), (D + 12, 1), (Fs + 12, 1), (E + 12, 1)],
    [(D + 12, 1), (B, 1), (G, 2)],
    [(A, 1), (D + 12, 0.5), (E + 12, 0.5), (Fs + 12, 1), (A + 12, 1)],
    [(G + 12, 1), (Fs + 12, 0.5), (E + 12, 0.5), (D + 12, 1), (B, 1)],
    [(Cs, 1), (E + 12, 1), (A, 1), (Cs, 1)],
    [(D + 12, 3), (REST, 1)],
    [(D + 12, 1.5), (Cs, 0.5), (B, 2)],
    [(Cs, 1), (A, 1), (Fs, 2)],
    [(B, 1), (D + 12, 1), (G + 12, 1.5), (Fs + 12, 0.5)],
    [(Fs + 12, 2), (A, 2)],
    [(G, 1), (B, 1), (E + 12, 1), (G + 12, 1)],
    [(Fs + 12, 1), (E + 12, 1), (Cs, 2)],
    [(B, 1), (D + 12, 1), (Cs, 1), (E + 12, 1)],
    [(D + 12, 2), (REST, 2)],
]


def make_counter():
    rng = np.random.default_rng(1)
    track = Track(bpm=96, bars=len(COUNTER_CHORDS))
    for bar, (root, third, fifth) in enumerate(COUNTER_CHORDS):
        start = bar * 4
        # Lute: eighth-note arpeggio over the chord
        pattern = [root, fifth, root + 12, third + 12, fifth, root + 12, third + 12, fifth + 12]
        for i, note in enumerate(pattern):
            accent = 1.0 if i % 2 == 0 else 0.75
            track.add(pluck(midi_hz(note), 1.6, 0.55, 0.995, rng), start + i * 0.5, 0.22 * accent)
        # Bass on beats 1 and 3
        for beat in (0, 2):
            track.add(pluck(midi_hz(root - 12), 2.0, 0.2, 0.998, rng), start + beat, 0.35)
        # Frame drum on 1 and 3, a lighter tap on the "and" of 4; shaker on the off-beats
        track.add(frame_drum(), start, 0.32)
        track.add(frame_drum(), start + 2, 0.24)
        track.add(frame_drum(), start + 3.5, 0.12)
        for i in range(4):
            track.add(shaker(), start + i + 0.5, 0.05)
    # Recorder melody, sitting back from the lute in the second half
    for bar, notes in enumerate(COUNTER_MELODY):
        at = bar * 4.0
        gain = 0.16 if bar < 8 else 0.13
        for note, beats in notes:
            if note is not None:
                track.add(recorder(midi_hz(note), beats * track.beat * 0.95), at, gain)
            at += beats
    return track.render()


# --- Table: A minor, 66 bpm --------------------------------------------------------------------

TABLE_CHORDS = [
    # One chord per two bars, voiced around octave 3-4
    (57, 60, 64, 67),  # Am7
    (53, 57, 60, 64),  # Fmaj7
    (48, 55, 60, 64),  # C
    (55, 59, 62, 67),  # G
    (57, 60, 64, 69),  # Am
    (53, 57, 60, 65),  # F
    (50, 57, 62, 65),  # Dm
    (52, 56, 59, 64),  # E
]
PENTATONIC = [69, 72, 74, 76, 79, 81, 84, 86, 88]  # A minor pentatonic, octaves 5 and 6


def make_table():
    rng = np.random.default_rng(2)
    track = Track(bpm=66, bars=len(TABLE_CHORDS) * 2, tail_seconds=6.0)
    chord_beats = 8
    for i, chord in enumerate(TABLE_CHORDS):
        start = i * chord_beats
        seconds = (chord_beats + 1.0) * track.beat  # overlap so the swells cross-fade
        for note in chord:
            track.add(pad(midi_hz(note), seconds), start - 0.5 if i else start, 0.14)
        # Low drone on A, renewed every chord so it never runs dry
        track.add(pad(midi_hz(45), seconds), start, 0.10)
    # Sparse bells, a phrase every bar, avoiding the E chord's clash with G and C
    for bar in range(len(TABLE_CHORDS) * 2):
        chord = TABLE_CHORDS[bar // 2]
        allowed = [n for n in PENTATONIC if (n % 12) in {c % 12 for c in chord} or n % 12 in (2, 9)]
        if bar // 2 == 7:
            allowed = [n for n in PENTATONIC if n % 12 in (4, 9)] + [80, 83]  # E, A, G#, B
        beat = 0.0
        while beat < 4.0:
            if rng.random() < 0.55:
                note = int(rng.choice(allowed))
                track.add(bell(midi_hz(note), 3.0), bar * 4 + beat, 0.10 * rng.uniform(0.6, 1.0))
            beat += float(rng.choice([1.0, 1.5, 2.0]))
    return track.render()


def write_ogg(name, samples):
    path = os.path.normpath(os.path.join(OUT, name))
    pcm = (np.clip(samples, -1.0, 1.0) * 32767).astype("<i2")
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, "loop.wav")
        with wave.open(wav_path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(pcm.tobytes())
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "4", path],
            check=True,
        )
    print("wrote %s (%.1f s)" % (path, len(samples) / RATE))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    write_ogg("counter_theme.ogg", make_counter())
    write_ogg("table_theme.ogg", make_table())
