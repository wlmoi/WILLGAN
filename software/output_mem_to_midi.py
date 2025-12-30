import numpy as np
from mido import Message, MidiFile, MidiTrack

# Path ke output.mem (784 Q5.10 signed hex)
mem_path = '../../hardware/layers/output.mem'
# Output MIDI
out_midi_path = 'output_layer3.mid'

# Baca output.mem
with open(mem_path, 'r') as f:
    lines = f.readlines()

# Konversi hex ke signed int16
vals = [int(x.strip(), 16) for x in lines]
vals = np.array([x if x < 0x8000 else x - 0x10000 for x in vals], dtype=np.int16)

# Q5.10 ke float
floats = vals / 1024.0

# Bentuk matriks 28x28 (time x pitch)
mat = floats.reshape(28, 28)

# Normalisasi ke velocity MIDI (0-127)
minv, maxv = mat.min(), mat.max()
if maxv - minv < 1e-6:
    velocities = np.zeros_like(mat, dtype=np.uint8)
else:
    velocities = ((mat - minv) / (maxv - minv) * 127).astype(np.uint8)

# Buat file MIDI
mid = MidiFile()
track = MidiTrack()
mid.tracks.append(track)

# Set tempo (opsional)
track.append(Message('program_change', program=0, time=0))

# Mapping: baris = waktu, kolom = pitch (misal MIDI note 60-87)
base_note = 60  # C4
for t in range(28):
    for p in range(28):
        vel = velocities[t, p]
        if vel > 0:
            track.append(Message('note_on', note=base_note + p, velocity=int(vel), time=0))
    # Lepas semua nada di akhir baris (waktu)
    track.append(Message('note_off', note=base_note, velocity=0, time=120))

mid.save(out_midi_path)
print(f'Saved MIDI to {out_midi_path}')
